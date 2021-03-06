class MembersController < ApplicationController
  load_and_authorize_resource :except => :create
  
  def index
    @title = "Member List"
    @order = Member.new.has_attribute?(params[:order]) ? params[:order] : Member::Default_sort_key
    if params[:desc] == "1"
      @order += " DESC" 
      @order_desc = true 
    end

    @members = @members.order(@order)
    if params[:active_only] == "1"
      @members = @members.active
    end

    if params[:filter] == "1"
      roles_array = []
      if params[:suspended] == "1"
        roles_array << "suspended"
      end
      if params[:alumni] == "1"
        roles_array << "alumni"
      end
      if params[:general_member] == "1"
        roles_array << "general_member"
      end
      if params[:exec] == "1"
        roles_array << "exec"
      end
      if params[:tracker_management] == "1"
        roles_array << "tracker_management"
      end
      if params[:head_of_tech] == "1"
        roles_array << "head_of_tech"
      end

      @members = @members.where(role: roles_array)
    end

    respond_to do |format|
      format.html
      format.vcf { render :layout => false }
    end
  end

  def show
    @title = "Member Display"

    respond_to do |format|
      format.html
      format.vcf { render :layout => false }
    end
  end

  def new
    @title = "New Member"
  end

  def create
    @member = Member.new(member_params)
    authorize! :create, @member
    
    if @member.save
      flash[:notice] = 'Member was successfully created.'
      redirect_to members_path
    else
      render :action => 'new'
    end
  end

  def edit
    @title = "Editing Member"
  end

  def update
    if @member.update_attributes(member_params)
      if can? :show, Member
        flash[:notice] = 'Member was successfully updated.'
        redirect_to(:action => 'show', :id => @member)
      else
        flash[:notice] = 'Thank you for keeping your information up to date!'
        redirect_to :controller => 'events', :action => 'index'
      end
    else
      render(:action => 'edit')
    end
  end

  def destroy
    @member.destroy
    flash[:notice] = 'Member was successfully destroyed.'
    redirect_to members_path
  end
  
  def tshirts
    @title = "T-Shirt Sizes"

    @shirt_sizes = @members.active.where.not(shirt_size: nil).sort_by {|m| [Member.shirt_size.values.index(m.shirt_size), m.namelast]}.group_by(&:shirt_size)
  end
  
  def roles
    @title = "Members by Role"

    if params[:show] == "all"
      members = Member.all
    else
      members = Member.active
    end
    
    @visible_roles = EventRole::Roles_All - [EventRole::Role_HoT, EventRole::Role_exec]
    @roles = @visible_roles.map do |role|
      counts = EventRole.where(role: role).group(:member_id).count
      { :role => role, :members =>
        members.reject do |m|
          # m.id == 5 test is so that Sam Abtek doesn't show up in results
          not counts.has_key? m.id or counts[m.id] == 0 or m.id == 5
        end.sort_by do |m|
          counts[m.id]
        end.reverse.map do |m|
          { :member => m, :count => counts[m.id] }
        end
      }
    end
  end

  def choose_filter
    respond_to do |format|
      format.js
    end
  end
  
  private
    def member_params
      if params[:member][:password].blank?
        params[:member].delete(:password)
        params[:member].delete(:password_confirmation)
      end
      
      if params[:member][:role] and (not current_member.is_at_least? params[:member][:role] or cannot? :manage, Member)
        params[:member].delete(:role)
      end
      
      if cannot? :manage, Timecard
        params[:member].delete(:payrate)
      end
      
      if not current_member.tracker_dev?
        params[:member].delete(:tracker_dev)
      end
      
      params.require(:member).permit(:password, :password_confirmation, :email, :namefirst, :namelast, :namenick, :title, :callsign, :shirt_size, :phone, :aim, :ssn, :payrate, :role, :tracker_dev)
    end
end
