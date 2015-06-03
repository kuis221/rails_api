require 'rails_helper'

feature 'Events section' do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'A Nice Place', country: 'CR', city: 'Curridabat', state: 'San Jose') }
  let(:permissions) { [] }

  before do
    Warden.test_mode!
    add_permissions permissions
    sign_in user
  end
  after { Warden.test_reset! }

  shared_examples_for 'a user that can attach expenses to events' do
    let(:event) { create(:due_event, campaign: campaign, place: place) }
    let(:brand1) { create(:brand, name: 'Brand 1', company_id: company.id) }
    let(:brand2) { create(:brand, name: 'Brand 2', company_id: company.id) }

    before do
      Kpi.create_global_kpis
      campaign.brands << [brand1, brand2]
      event.campaign.update_attribute(:modules, 'expenses' => {
        'settings' => { 'categories' => %w(Phone) } })
    end

    scenario 'can attach an expense to event' do
      with_resque do # So the document is processed
        visit event_path(event)

        click_js_button 'Add Expense'

        within visible_modal do
          attach_file 'file', 'spec/fixtures/file.pdf'

          # Test validations
          click_js_button 'Create'
          expect(find_field('Category', visible: false)).to have_error('This field is required.')

          select_from_chosen 'Phone', from: 'Category'
          select_from_chosen 'Brand 2', from: 'Brand'
          fill_in 'Date', with: '01/01/2014'
          fill_in 'Amount', with: '13'
          expect(page).to have_content('File attached: file.pdf')

          wait_for_photo_to_process 15 do
            click_js_button 'Create'
          end
        end
        ensure_modal_was_closed

        within '.details_box.box_expenses' do
          expect(page).to have_content 'Phone'
          expect(page).to have_content '$13.00'
        end
        asset = AttachedAsset.last
        expect(asset.file_file_name).to eql 'file.pdf'

        # Test user can preview and download the receipt
        hover_and_click '#expenses-list [id^="event_expense"]', 'View Receipt'

        within visible_modal do
          src = asset.preview_url(:medium, timestamp: false)
          expect(page).to have_xpath("//img[starts-with(@src, \"#{src}\")]", wait: 10)
          find('.slider').hover

          src = asset.file.url(:original, timestamp: false).gsub('http:', 'https:')
          expect(page).to have_link('Download')
          expect(page).to have_xpath("//a[starts-with(@href, \"#{src}\")]")
        end
      end
    end
  end

  shared_examples_for 'a user that can split expenses' do
    let(:event) { create(:due_event, campaign: campaign, place: place) }
    let(:brand1) { create(:brand, name: 'Brand 1', company_id: company.id) }
    let(:brand2) { create(:brand, name: 'Brand 2', company_id: company.id) }

    before do
      Kpi.create_global_kpis
      campaign.brands << [brand1, brand2]
      event.campaign.update_attribute(:modules, 'expenses' => {
        'settings' => { 'categories' => %w(Phone Other) } })
    end

    scenario 'can split an expense' do
      visit event_path(event)

      click_js_button 'Add Expense'

      within visible_modal do
        expect(page).to_not have_button('Split Expense')

        select_from_chosen 'Phone', from: 'Category'
        select_from_chosen 'Brand 2', from: 'Brand'
        fill_in 'Date', with: '01/01/2014'
        fill_in 'Amount', with: '500'

        click_js_button 'Split Expense'
      end

      within visible_modal do
        expect(page).to have_selector('.split-expense-form .expense-item', count: 2)
        expect(page).to have_content('TOTAL:$0')
        expect(page).to have_content('$500 left')

        click_js_link 'Add Expense'
        expect(page).to have_selector('.split-expense-form .expense-item', count: 3)

        expense_items = page.all('.split-expense-form .expense-item')

        within(expense_items[0]) do
          expect(find_field('event_expense_percentage').value).to eql ''
          select_from_chosen 'Phone', from: 'Category'
          select_from_chosen 'Brand 1', from: 'Brand'
          fill_in 'Date', with: '01/01/2014'
          fill_in 'Amount', with: '300'
          expect(find_field('event_expense_percentage').value).to eql '60'
        end

        within(expense_items[1]) do
          expect(find_field('event_expense_percentage').value).to eql '0'
          select_from_chosen 'Other', from: 'Category'
          select_from_chosen 'Brand 2', from: 'Brand'
          fill_in 'Date', with: '02/02/2014'
          fill_in 'Amount', with: '200'
          expect(find_field('event_expense_percentage').value).to eql '40'
        end

        within(expense_items[2]) do
          click_js_link 'Remove Expense'
        end

        expect(page).to have_selector('.split-expense-form .expense-item', count: 2)
        expect(page).to have_content('TOTAL:$500')
        expect(page).to have_content('$0 left')

        #click_js_button 'Create Expenses'
      end
    end
  end

  feature 'admin user', js: true, search: true do
    let(:role) { create(:role, company: company) }

    it_behaves_like 'a user that can attach expenses to events'
    it_behaves_like 'a user that can split expenses'
  end
end
