DROP VIEW IF EXISTS campaign_users;
CREATE OR REPLACE VIEW campaign_users AS
 SELECT memberships.memberable_id AS campaign_id,
    memberships.company_user_id,
        CASE
            WHEN ((campaigns.aasm_state)::text = 'active'::text) THEN true
            ELSE false
        END AS active,
    'campaign'::text AS via
   FROM (memberships
     JOIN campaigns ON (((campaigns.id = memberships.memberable_id) AND ((memberships.memberable_type)::text = 'Campaign'::text))))
UNION
 SELECT brands_campaigns.campaign_id,
    memberships.company_user_id,
    (brands.active AND ((campaigns.aasm_state)::text = 'active'::text)) AS active,
    'brand'::text AS via
   FROM (((brands_campaigns
     JOIN memberships ON (((memberships.memberable_id = brands_campaigns.brand_id) AND ((memberships.memberable_type)::text = 'Brand'::text))))
     JOIN campaigns ON ((campaigns.id = brands_campaigns.campaign_id)))
     JOIN brands ON (((brands.id = brands_campaigns.brand_id) AND (brands.active = true))))
UNION
 SELECT brand_portfolios_campaigns.campaign_id,
    memberships.company_user_id,
    (brand_portfolios.active AND ((campaigns.aasm_state)::text = 'active'::text)) AS active,
    'brand'::text AS via
   FROM (((brand_portfolios_campaigns
     JOIN memberships ON (((memberships.memberable_id = brand_portfolios_campaigns.brand_portfolio_id) AND ((memberships.memberable_type)::text = 'Brand'::text))))
     JOIN campaigns ON ((campaigns.id = brand_portfolios_campaigns.campaign_id)))
     JOIN brand_portfolios ON (((brand_portfolios.id = brand_portfolios_campaigns.brand_portfolio_id) AND (brand_portfolios.active = true))));

DROP VIEW IF EXISTS event_team_members;
CREATE OR REPLACE VIEW event_team_members AS 
   SELECT events.id AS event_id,
    array_agg(users.first_name || ' ' || users.last_name) AS names,
    array_agg(company_users.id) AS ids
   FROM events
     LEFT JOIN teamings ON teamings.teamable_id = events.id AND teamings.teamable_type = 'Event'
     LEFT JOIN teams ON teams.id = teamings.team_id
     LEFT JOIN memberships ON (memberships.memberable_id = events.id AND memberships.memberable_type = 'Event') OR 
                              (memberships.memberable_id = teams.id AND memberships.memberable_type = 'Team')
     LEFT JOIN company_users ON company_users.id = memberships.company_user_id
     LEFT JOIN users ON users.id = company_users.user_id
   GROUP BY events.id;


DROP VIEW IF EXISTS event_data_results;
CREATE OR REPLACE VIEW event_data_results AS 
SELECT r.resultable_id event_id, ff.id form_field_id, CASE 
                    WHEN ff.type = 'FormField::Dropdown' OR ff.type = 'FormField::Radio' THEN hstore('value', CASE WHEN ff.kpi_id IS NULL THEN ffo.name ELSE k.text END)
                    WHEN ff.type = 'FormField::Percentage' OR ff.type = 'FormField::LikertScale' OR ff.type = 'FormField::Summation' THEN r.hash_value
                    WHEN ff.type = 'FormField::Checkbox' THEN hstore('value', array_to_string(array_agg(CASE WHEN ff.kpi_id IS NULL THEN ffc.name ELSE kc.text END), ', '))
                    ELSE hstore('value', r.value)
                  END as value
FROM form_field_results r
INNER JOIN form_fields ff ON ff.id=r.form_field_id
LEFT JOIN form_field_options ffo ON ff.kpi_id IS NULL AND (ff.type = 'FormField::Dropdown' OR ff.type = 'FormField::Radio') AND ffo.form_field_id=ff.id AND ffo.id::text=r.value
LEFT JOIN kpis_segments k ON ff.kpi_id IS NOT NULL AND k.kpi_id=ff.kpi_id AND k.id::text=r.value
LEFT JOIN form_field_options ffc ON ff.kpi_id IS NULL AND ff.type = 'FormField::Checkbox' AND ffc.form_field_id=ff.id AND r.hash_value ? ffc.id::text
LEFT JOIN kpis_segments kc ON ff.kpi_id IS NOT NULL AND kc.kpi_id=ff.kpi_id AND r.hash_value ? kc.id::text
WHERE r.resultable_type='Event'
GROUP BY r.resultable_id, ff.id, ff.type, ff.kpi_id, ffo.name, k.text, r.hash_value, r.value;


DROP VIEW IF EXISTS activity_results;
CREATE OR REPLACE VIEW activity_results AS 
SELECT r.resultable_id activity_id, ff.id form_field_id, CASE 
                    WHEN ff.type = 'FormField::Dropdown' OR ff.type = 'FormField::Radio' THEN hstore('value', ffo.name)
                    WHEN ff.type = 'FormField::Percentage' OR ff.type = 'FormField::LikertScale' OR ff.type = 'FormField::Summation' THEN r.hash_value
                    WHEN ff.type = 'FormField::Checkbox' THEN hstore('value', array_to_string(array_agg(ffc.name), ', '))
                    ELSE hstore('value', r.value)
                  END as value
FROM form_field_results r
INNER JOIN form_fields ff ON ff.id=r.form_field_id
LEFT JOIN form_field_options ffo ON (ff.type = 'FormField::Dropdown' OR ff.type = 'FormField::Radio') AND ffo.form_field_id=ff.id AND ffo.id::text=r.value
LEFT JOIN form_field_options ffc ON ff.type = 'FormField::Checkbox' AND ffc.form_field_id=ff.id AND r.hash_value ? ffc.id::text
WHERE r.resultable_type='Activity'
GROUP BY r.resultable_id, ff.id, ff.type, ff.kpi_id, ffo.name, r.hash_value, r.value;
