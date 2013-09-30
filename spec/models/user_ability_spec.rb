require "spec_helper"
require "cancan/matchers"

describe "User" do
  describe "abilities" do
    subject(:ability){ Ability.new(user) }
    let(:user){ nil }
    let(:company) { FactoryGirl.create(:company) }

    before do
      User.current = user
    end

    context "when it is a super user" do
      let(:user){ FactoryGirl.create(:company_user,  company: company, role: FactoryGirl.create(:role, is_admin: true), user: FactoryGirl.create(:user,  current_company: company)).user }


      it{ should_not be_able_to(:manage, Company) }
      it{ should_not be_able_to(:create, Company) }
      it{ should_not be_able_to(:edit, Company) }
      it{ should_not be_able_to(:destroy, Company) }
      it{ should_not be_able_to(:index, Company) }

      it { should be_able_to(:create, Brand)}
      it { should_not be_able_to(:manage, FactoryGirl.create(:brand))}

      it { should be_able_to(:create, Event) }
      it { should be_able_to(:manage, FactoryGirl.create(:event, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:event, company_id: company.id + 1 )) }

      it { should be_able_to(:create, Team) }
      it { should be_able_to(:manage, FactoryGirl.create(:team, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:team, company_id: company.id + 1 )) }

      it { should be_able_to(:create, Task) }
      it { should be_able_to(:manage, FactoryGirl.create(:task, event: FactoryGirl.create(:event, company_id: company.id))) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:task, event: FactoryGirl.create(:event, company_id: company.id + 1 ))) }

      it { should be_able_to(:create, Area) }
      it { should be_able_to(:manage, FactoryGirl.create(:area, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:area, company_id: company.id + 1 )) }

      it { should be_able_to(:create, BrandPortfolio) }
      it { should be_able_to(:manage, FactoryGirl.create(:brand_portfolio, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:brand_portfolio, company_id: company.id + 1 )) }

      it { should be_able_to(:create, Campaign) }
      it { should be_able_to(:manage, FactoryGirl.create(:campaign, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:campaign, company_id: company.id + 1 )) }

      it { should be_able_to(:create, DateRange) }
      it { should be_able_to(:manage, FactoryGirl.create(:date_range, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:date_range, company_id: company.id + 1 )) }

      it { should be_able_to(:create, DateItem) }
      it { should be_able_to(:manage, FactoryGirl.create(:date_item, date_range:  FactoryGirl.create(:date_range, company_id: company.id))) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:date_item, date_range:  FactoryGirl.create(:date_range, company_id: company.id + 1) )) }

      it { should be_able_to(:create, DayPart) }
      it { should be_able_to(:manage, FactoryGirl.create(:day_part, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:day_part, company_id: company.id + 1 )) }

      it { should be_able_to(:create, DayItem) }
      it { should be_able_to(:manage, FactoryGirl.create(:day_item, day_part:  FactoryGirl.create(:day_part, company_id: company.id))) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:day_item, day_part:  FactoryGirl.create(:day_part, company_id: company.id + 1) )) }

      it { should be_able_to(:create, Kpi) }
      it { should be_able_to(:manage, FactoryGirl.create(:kpi, company_id: company.id)) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:kpi, company_id: company.id + 1 )) }

      it { should be_able_to(:create, Place) }

      it { should be_able_to(:create, EventExpense) }
      it { should be_able_to(:manage, FactoryGirl.create(:event_expense, event: FactoryGirl.create(:event, company_id: company.id))) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:event_expense, event: FactoryGirl.create(:event, company_id: company.id + 1))) }

      it { should be_able_to(:create, Comment) }
      it { should be_able_to(:manage, FactoryGirl.create(:comment, commentable: FactoryGirl.create(:event, company_id: company.id))) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:comment, commentable: FactoryGirl.create(:event, company_id: company.id + 1))) }
      it { should be_able_to(:manage, FactoryGirl.create(:comment, commentable: FactoryGirl.create(:task, event: FactoryGirl.create(:event, company_id: company.id)))) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:comment, commentable: FactoryGirl.create(:task, event: FactoryGirl.create(:event, company_id: company.id + 1)))) }


      it { should be_able_to(:create, AttachedAsset) }
      it { should be_able_to(:manage, FactoryGirl.create(:attached_asset, attachable: FactoryGirl.create(:event, company_id: company.id))) }
      it { should_not be_able_to(:manage, FactoryGirl.create(:attached_asset, attachable: FactoryGirl.create(:event, company_id: company.id + 1))) }

    end
  end
end