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

