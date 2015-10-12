require 'rails_helper'

feature 'Events section', js: true do
  let(:company) { create(:company) }
  let(:campaign) { create(:campaign, company: company) }
  let(:user) { create(:user, company: company, role_id: role.id) }
  let(:company_user) { user.company_users.first }
  let(:place) { create(:place, name: 'A Nice Place', country: 'CR', city: 'Curridabat', state: 'San Jose') }
  let(:role) { create(:non_admin_role, company: company) }
  let(:permissions) { [] }

  before do
    Warden.test_mode!
    add_permissions permissions
    company_user.places << place
    company_user.campaigns << campaign
    sign_in user
  end
  after { Warden.test_reset! }

  feature 'create' do
    let(:permissions) { [[:show, 'Event'], [:index_expenses, 'Event'], [:create_expense, 'Event']] }
    let(:event) { create(:due_event, campaign: campaign, place: place) }
    let(:brand1) { create(:brand, name: 'Brand 1', company_id: company.id) }
    let(:brand2) { create(:brand, name: 'Brand 2', company_id: company.id) }

    before do
      campaign.brands << [brand1, brand2]
      event.campaign.update_attribute(:modules, 'expenses' => {
                                        'settings' => { 'categories' => %w(Phone) } })
    end

    scenario 'user can attach a expense to event' do
      with_resque do # So the document is processed
        visit event_path(event)

        click_js_button 'Record Expense'

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

        within '#event-expenses' do
          expect(page).to have_content 'Phone'
          expect(page).to have_content '$13.00'
        end
        asset = AttachedAsset.last
        expect(asset.file_file_name).to eql 'file.pdf'

        # Test user can preview and download the receipt
        hover_and_click expense_row(asset.attachable), 'View Receipt'

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

  feature 'split' do
    let(:event) { create(:due_event, campaign: campaign, place: place) }
    let(:brand1) { create(:brand, name: 'Brand 1', company_id: company.id) }
    let(:brand2) { create(:brand, name: 'Brand 2', company_id: company.id) }

    before do
      campaign.brands << [brand1, brand2]
      event.campaign.update_attribute(:modules, 'expenses' => {
                                        'settings' => {
                                          'categories' => %w(Phone Other) } })
    end

    feature 'new expense' do
      let(:permissions) { [[:show, 'Event'], [:index_expenses, 'Event'], [:create_expense, 'Event']] }

      scenario 'can split an expense' do
        visit event_path(event)

        click_js_button 'Record Expense'

        within visible_modal do
          expect(page).to_not have_button('Split Expense')

          select_from_chosen 'Phone', from: 'Category'
          select_from_chosen 'Brand 2', from: 'Brand'
          fill_in 'Amount', with: '500'
          fill_in 'Merchant', with: 'the merchant'
          fill_in 'Description', with: 'this is the description'
          unicheck 'Reimbursable'
          unicheck 'Billable'
          attach_file 'file', 'spec/fixtures/photo.jpg'
          fill_in 'Date', with: '01/01/2014'

          click_js_button 'Split Expense'
        end

        within visible_modal do
          expect(page).to have_selector('.split-expense-form .expense-item', count: 2)
          expect(page).to have_content('TOTAL:$0')
          expect(page).to have_content('$500.00 left')

          click_js_link 'Add Expense'
          click_js_link 'Add Expense'
          expect(page).to have_selector('.split-expense-form .expense-item', count: 4)

          within expense_items[0] do
            expect(find_field('event_expense_percentage').value).to eql ''
            select_from_chosen 'Phone', from: 'Category'
            select_from_chosen 'Brand 1', from: 'Brand'
            fill_in 'Date', with: '01/01/2014'
            fill_in 'Amount', with: '200'
            expect(page).to have_field('event_expense_percentage', with: '40')
            expect(page).to_not have_content('$300.00 left')
          end

          within expense_items[1] do
            expect(find_field('event_expense_percentage').value).to eql '0'
            select_from_chosen 'Other', from: 'Category'
            select_from_chosen 'Brand 2', from: 'Brand'
            fill_in 'Date', with: '02/02/2014'
            fill_in 'Amount', with: '225'
            expect(page).to have_field('event_expense_percentage', with: '45')
            expect(page).to_not have_content('$75.00 left')
          end

          within expense_items[2] do
            expect(find_field('event_expense_percentage').value).to eql '0'
            select_from_chosen 'Other', from: 'Category'
            select_from_chosen 'Brand 1', from: 'Brand'
            fill_in 'Date', with: '02/03/2014'
            fill_in 'Amount', with: '75'
            expect(page).to have_field('event_expense_percentage', with: '15')
            expect(page).to_not have_content('$0.00 left')
          end

          within expense_items[3] do
            click_js_link 'Remove Expense'
          end

          expect(page).to have_selector('.split-expense-form .expense-item', count: 3)
          expect(page).to have_content('TOTAL:$500')
          expect(page).to_not have_content('$0.00 left')

          click_js_button 'Create Expenses'
          wait_for_ajax(15)
        end
        ensure_modal_was_closed

        within expenses_list do
          expect(page).to have_content 'Phone'
          expect(page).to have_content 'Other'
        end
        event.event_expenses.each do |expense|
          expect(expense.description).to eql 'this is the description'
          expect(expense.merchant).to eql 'the merchant'
          expect(expense.billable).to be_truthy
          expect(expense.reimbursable).to be_truthy
          expect(expense.receipt.file_file_name).to eql 'photo.jpg'
        end
      end

      scenario 'split evenly a expense' do
        visit event_path(event)

        click_js_button 'Record Expense'

        within visible_modal do
          expect(page).to_not have_button('Split Expense')

          select_from_chosen 'Phone', from: 'Category'
          fill_in 'Amount', with: '200'
          fill_in 'Date', with: '01/01/2014'

          click_js_button 'Split Expense'
        end

        within visible_modal do
          expect(page).to have_selector('.split-expense-form .expense-item', count: 2)
          expect(page).to have_content('TOTAL:$0')
          expect(page).to have_content('$200.00 left')
          click_js_button 'Split Evenly'

          within expense_items[0] do
            expect(page).to have_field('Amount', with: '100.00')
            expect(page).to have_field('Percent', with: '50')
          end

          within expense_items[1] do
            expect(page).to have_field('Amount', with: '100.00')
            expect(page).to have_field('Percent', with: '50')
          end

          click_js_link 'Add Expense'

          click_js_button 'Split Evenly'

          within expense_items[0] do
            expect(page).to have_field('Amount', with: '66.68')
            expect(page).to have_field('Percent', with: '33.34')
          end

          within expense_items[1] do
            expect(page).to have_field('Amount', with: '66.66')
            expect(page).to have_field('Percent', with: '33.33')
          end

          within expense_items[2] do
            expect(page).to have_field('Amount', with: '66.66')
            expect(page).to have_field('Percent', with: '33.33')
          end

          expect(page).to have_content 'TOTAL:$200'
        end
      end

      scenario 'canceling a split modal will show the new expense dialog' do
        visit event_path(event)

        click_js_button 'Record Expense'

        within visible_modal do
          expect(page).to_not have_button('Split Expense')

          select_from_chosen 'Phone', from: 'Category'
          fill_in 'Amount', with: '200'
          fill_in 'Date', with: '01/01/2014'

          click_js_button 'Split Expense'
        end

        within visible_modal do
          expect(page).to have_content('Split Expense')
          click_js_button 'Cancel'
        end

        expect(page).to have_content('New Expense')
        within visible_modal do
          expect(page).to have_field('Amount', with: '200')
          expect(page).to have_field('Category', with: 'Phone', visible: false)
          expect(page).to have_field('Date', with: '01/01/2014')
        end
      end
    end

    feature 'existing expense' do
      let(:event_expense) { create(:event_expense, amount: 500, event: event, category: 'Phone') }
      let(:permissions) { [[:show, 'Event'], [:index_expenses, 'Event'], [:edit_expense, 'Event']] }

      scenario 'can split an expense' do
        event_expense
        visit event_path(event)

        within expense_row(event_expense) do
          click_js_button 'Edit Expense'
        end

        within visible_modal do
          click_js_button 'Split Expense'
        end

        within visible_modal do
          expect(page).to have_selector('.split-expense-form .expense-item', count: 2)
          expect(page).to have_content('TOTAL:$0')
          expect(page).to have_content('$500.00 left')

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
          expect(page).to_not have_content('$0.00 left')

          click_js_button 'Create Expenses'
        end
        ensure_modal_was_closed

        within expenses_list do
          expect(page).to have_content 'Phone'
          expect(page).to have_content 'Other'
        end
        event.event_expenses.each do |expense|
          expect(expense.description).to eql 'this is the description'
          expect(expense.merchant).to eql 'the merchant'
          expect(expense.billable).to be_truthy
          expect(expense.reimbursable).to be_truthy
          expect(expense.receipt.file_file_name).to eql 'photo.jpg'
        end
      end
    end
  end

  def expenses_list
    '#expenses-list'
  end

  def expense_row(expense)
    row = find("#expenses-list tr#event_expense_#{expense.id}")
    row.hover
    row
  end

  def expense_items
    page.all('.split-expense-form .expense-item')
  end
end
