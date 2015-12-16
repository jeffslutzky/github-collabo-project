class IssuesController < ApplicationController
  before_action :set_issue, only: [:show, :edit, :update, :destroy]
  before_filter :require_login, :except => :event_handler
  protect_from_forgery except: :event_handler

  def index
    @project = Project.find(params[:project_id])
    @issues = @project.issues
  end

  def show
    @project = Project.find(params[:project_id])
  end

  def new
    @issue = Issue.new
    @project = Project.find(params[:project_id])
  end

  def edit
    @project = Project.find(params[:project_id])
    @issue = Issue.find(params[:id])
  end

  def create
      @project = Project.find(params[:project_id])
      @issue = Issue.new(issue_params)
      @issue.project = @project

    respond_to do |format|
      if @issue.save

            # Github object to create new issue
             github = Github.new user: current_user.username, repo:"#{@project.name}"
             github.oauth_token = session["user_token"]

             #Gathering milestone ID from new issues form
             milestone_id = params['issue']['milestones']
      begin
             #Creating new issue on github with milestone ID
             github.issues.create title: "#{@issue.title}",
               body: "#{@issue.body}"
               # assignee: "octocat",
               # milestone: "#{milestone_id}"
     rescue Github::Error::ServiceError
       format.html { redirect_to project_issue_path(@project, @issue), notice: 'Issue has been saved on local but you do not have access to push to remote.' }
     end

        format.html { redirect_to project_issue_path(@project, @issue), notice: 'Milestone was successfully created.' }
        format.json { render :show, status: :created, location: project_issue_path }
      else
        format.html { render :new }
        format.json { render json: project_issue_path.errors, status: :unprocessable_entity }
      end
    end
  end


  def update
    binding.pry
    respond_to do |format|
      if @issue.update(issue_params)
        format.html { redirect_to project_issue_path, notice: 'Milestone was successfully updated.'  }
        format.json { render :show, status: :ok, location: @issue }
      else
        format.html { render :edit }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @issue.destroy
    respond_to do |format|
      format.html { redirect_to issues_url, notice: 'Issue was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def set_issue
      @issue = Issue.find(params[:id])
    end

    def issue_params
      params.require(:issue).permit(:title, :body, :milestone_id, :created_at, :closed_at)
    end
end
