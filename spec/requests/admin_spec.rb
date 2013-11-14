require 'spec_helper'

describe "AdminPages" do
  describe "GET /admin" do
    before do
      @user = FactoryGirl.create(:admin_user)
      sign_in @user
    end

    describe "check all pages:" do
      all_admin_pages = Dir['app/admin/*.rb'].map { |entry| entry[/[^\/]+\.rb/][0..-4] }
      if all_admin_pages.delete('dashboard')
        it 'dashboard' do
          get send("admin_dashboard_path")
          response.status.should be(200)
        end
      end

      all_admin_pages.each do |path|
        it "#{path} -> INDEX" do
          get send("admin_#{path}_path")
          response.status.should be(200)
        end
      end

      all_admin_pages.each do |path|
        path = path.singularize
        if path != 'place'
          it "#{path} -> NEW" do
            get send("new_admin_#{path}_path")
            response.status.should be(200)
          end

          it "#{path} -> CREATE" do
            #not just attributes_for, because then associated ids are not set up
            test_object = FactoryGirl.build(path)
            attributes = test_object.attributes
            #user should have password, generated with #attributes_for
            attributes.merge!(FactoryGirl.attributes_for(:admin_user)) if path == 'admin_user'
            attributes.merge!({admin_email: "testemail@brandscopic.com"}) if path == 'company'
            attributes.except!(:reference, :place_id) if path == 'places'
            #attributes.reject!{|a| !test_object.class.accessible_attributes.include?(a) }

            post send("admin_#{path.pluralize}_path"),
                 { path => attributes }
            response.status.should be(302)
            response.should redirect_to(:action => :show, :id => assigns(path))
          end
        end

        it "#{path} -> EDIT" do
          get send("edit_admin_#{path}_path", FactoryGirl.create(path))
          response.status.should be(200)
        end

        it "#{path} -> UPDATE" do
          object = FactoryGirl.create(path)
          attributes = FactoryGirl.attributes_for(path)
          #except password for user
          attributes.except!(:password, :password_confirmation) if path == 'user'
          put send("admin_#{path}_path", object),
                { path => attributes }
          response.status.should be(302)
          updated_object = assigns(path)
          response.should redirect_to(:action => :show, :id => updated_object)

        end

        it "#{path} -> SHOW" do
          get send("admin_#{path}_path", FactoryGirl.create(path))
          response.status.should be(200)
        end

        if path != 'place'
          it "#{path} -> DELETE" do
            delete send("admin_#{path}_path", FactoryGirl.create(path))
            response.status.should be(302)
          end
        end
      end
    end
  end
end