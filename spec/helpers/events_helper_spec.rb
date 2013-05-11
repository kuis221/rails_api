require 'spec_helper'

describe EventsHelper do
  describe "event_tasks_progress_bar" do
    it "returns nil if no tasks" do
      helper.event_tasks_progress_bar([]).should == nil
    end

    it "returns a completed bar with 100% if all tasks are completed" do
      tasks = FactoryGirl.build_list(:task, 3, completed: true, user_id: 1)
      rendered = helper.event_tasks_progress_bar(tasks)
      rendered.should =~ /3 of 3 Tasks Have Been Assigned. 3 are Completed./
      rendered.should =~ /<div class="bar bar-completed" style="width: 100%">100%<\/div>/
      rendered.should =~ /<div class="bar bar-assigned" style="width: 0%">0%<\/div>/
      rendered.should =~ /<div class="bar-unassigned" style="width: 0%">0%<\/div>/
    end

    it "returns a assigned bar with 100% if all tasks are assigned" do
      tasks = FactoryGirl.build_list(:task, 3, completed: false, user_id: 1)
      rendered = helper.event_tasks_progress_bar(tasks)
      rendered.should =~ /3 of 3 Tasks Have Been Assigned. 0 are Completed./
      rendered.should =~ /<div class="bar bar-completed" style="width: 0%">0%<\/div>/
      rendered.should =~ /<div class="bar bar-assigned" style="width: 100%">100%<\/div>/
      rendered.should =~ /<div class="bar-unassigned" style="width: 0%">0%<\/div>/
    end

    it "returns a unassigned bar with 100% if there are no tasks assigned" do
      tasks = FactoryGirl.build_list(:task, 3, completed: false, user_id: nil)
      rendered = helper.event_tasks_progress_bar(tasks)
      rendered.should =~ /0 of 3 Tasks Have Been Assigned. 0 are Completed./
      rendered.should =~ /<div class="bar bar-completed" style="width: 0%">0%<\/div>/
      rendered.should =~ /<div class="bar bar-assigned" style="width: 0%">0%<\/div>/
      rendered.should =~ /<div class="bar-unassigned" style="width: 100%">100%<\/div>/
    end

    it "returns all bars with the correct width" do
      tasks = FactoryGirl.build_list(:task, 3, completed: false, user_id: 1)
      tasks += FactoryGirl.build_list(:task, 3, completed: true, user_id: 1)
      tasks += FactoryGirl.build_list(:task, 3, completed: false, user_id: nil)
      rendered = helper.event_tasks_progress_bar(tasks)
      rendered.should =~ /6 of 9 Tasks Have Been Assigned. 3 are Completed./
      rendered.should =~ /<div class="bar bar-completed" style="width: 33%">33%<\/div>/
      rendered.should =~ /<div class="bar bar-assigned" style="width: 33%">33%<\/div>/
      rendered.should =~ /<div class="bar-unassigned" style="width: 34%">34%<\/div>/
    end
  end
end