module ApplicationHelper
  def ajax_link_to(text, options)
    return "<a href=\"javascript:doAndReload('" +
           url_for(options) +
           "')\">" +
           text +
           "</a>";
  end
  
  def conditional_link_to(title, controller, action)
    if (current_member().authorized?("%s/%s" % [controller, action]))
      link_to(title, {:controller => controller, :action => action})
    else
      ""
    end
  end

  def conditional_link_to_remote(title, controller, action, update, html = {})
    if (current_member().authorized?("%s/%s" % [controller, action]))
      link_to(title, { :url => {:controller => controller, :action => action}, :update => update }, html, :remote => true)
    else
      ""
    end
  end

  Date.class_eval do
    def ago
      return "today" if Date.today-self == 0 
      return "yesterday" if Date.today-self == 1
      return "tomorrow" if Date.today-self == -1
      return (Date.today-self).to_s+" days ago" if Date.today-self > 0
      return "in "+(self-Date.today).to_s+" days" if Date.today-self < 0
    end
  end

  def iphone_user_agent?
    controller.iphone_user_agent?
  end

  def app_version
    begin
      %x{git log --pretty=format:"%h"  -n1}
    rescue
      "?"
    end
  end
  
  def get_sidebar_monthdates
    startdate = DateTime.new(Time.now.year, Time.now.month, 1)
    enddate = DateTime.new(Time.now.year, Time.now.month, Time.days_in_month(Time.now.month))
    Eventdate.where(["UNIX_TIMESTAMP(enddate) > ? AND UNIX_TIMESTAMP(startdate) < ?", startdate.to_i, enddate.to_i]).order("startdate ASC").includes(:event).to_a
  end
  
  def load_account_totals
    @accstart = Account::Magic_Date unless @accstart
    @accend = Account::Future_Magic_Date unless @accend
    
    @accounts_receivable_total = Journal.sum(:amount, :conditions => ["date >= '" + @accstart+ "' AND date < '"+ @accend +"' AND date_paid IS NULL AND account_id in (?)", Account::Credit_Accounts])
    @accounts_receivable_total = (@accounts_receivable_total == nil) ? 0 : @accounts_receivable_total
    @accounts_received_total = Journal.sum(:amount, :conditions => ["date >= '" + @accstart+ "' AND date < '"+ @accend +"'  AND date_paid IS NOT NULL AND account_id in (?)", Account::Credit_Accounts])
    @accounts_received_total = (@accounts_received_total == nil) ? 0 : @accounts_received_total
    @accounts_payable_total = Journal.sum(:amount, :conditions => ["date >= '" + @accstart+ "'  AND date < '"+ @accend +"' AND date_paid IS NULL AND account_id in (?)", Account::Debit_Accounts])
    @accounts_payable_total = (@accounts_payable_total == nil) ? 0 : @accounts_payable_total
    @accounts_paid_total = Journal.sum(:amount, :conditions => ["date >= '" + @accstart+ "' AND date < '"+ @accend +"'  AND date_paid IS NOT NULL AND account_id in (?)", Account::Debit_Accounts])
    @accounts_paid_total = (@accounts_paid_total == nil) ? 0 : @accounts_paid_total

    @credit_JEs = Journal.find(:all, :conditions => ["date >= '" + @accstart+ "' AND date < '"+ @accend +"'  AND account_id in (?)", Account::Credit_Accounts], :order => "date DESC")
    @debit_JEs = Journal.find(:all, :conditions => ["date >= '" + @accstart+ "' AND date < '"+ @accend +"'  AND account_id in (?)", Account::Debit_Accounts], :order => "date DESC")

    @credit_categories = Journal.find(:all,:group=>"paymeth_category",:select=>"SUM(amount) AS amount, id,paymeth_category", :conditions => ["date >= '#{@accstart}' AND date < '#{@accend}' AND account_id in (?)",Account::Credit_Accounts])
    @debit_categories = Journal.find(:all,:group=>"paymeth_category",:select=>"SUM(amount) AS amount, id,paymeth_category", :conditions => ["date >= '#{@accstart}' AND date < '#{@accend}' AND account_id in (?)",Account::Debit_Accounts])
    @cat_totals = Hash.new(0)

    @credit_categories.each do |category|
      @cat_totals[category.paymeth_category]+=category.amount
    end

    @debit_categories.each do |category|
      @cat_totals[category.paymeth_category]-=category.amount
    end
  end
end
