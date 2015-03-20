class CreateUserCampaignsView < ActiveRecord::Migration
  def up
    execute 'CREATE VIEW campaign_users AS
                SELECT memberable_id AS campaign_id, company_user_id, CASE WHEN aasm_state=\'active\' THEN true ELSE false END as active, \'campaign\' as via
                FROM memberships
                INNER JOIN campaigns ON "campaigns".id=memberable_id AND "memberships".memberable_type=\'Campaign\'
             UNION
                SELECT campaign_id, company_user_id, (brands.active AND campaigns.aasm_state=\'active\') active, \'brand\' as via FROM "brands_campaigns"
                INNER JOIN "memberships" ON "memberships"."memberable_id" = "brands_campaigns"."brand_id" AND "memberships".memberable_type=\'Brand\'
                INNER JOIN "campaigns" ON "campaigns".id="brands_campaigns".campaign_id
                INNER JOIN "brands" ON "brands"."id" = "brands_campaigns"."brand_id" AND "brands"."active" = \'t\'
             UNION
                SELECT campaign_id, company_user_id, (brand_portfolios.active AND campaigns.aasm_state=\'active\') active, \'brand\' as via
                FROM "brand_portfolios_campaigns"
                INNER JOIN "memberships" ON "memberships".memberable_id = "brand_portfolios_campaigns".brand_portfolio_id AND "memberships".memberable_type=\'Brand\'
                INNER JOIN campaigns ON campaigns.id=brand_portfolios_campaigns.campaign_id
                INNER JOIN "brand_portfolios" ON "brand_portfolios"."id" = "brand_portfolios_campaigns"."brand_portfolio_id" AND
                                                 "brand_portfolios"."active" = \'t\''
  end

  def down
    execute 'DROP view campaign_users'
  end
end
