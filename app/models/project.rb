class Project < ActiveRecord::Base
  belongs_to :project_state
  has_many :tasks, :dependent => :destroy
  has_many :accountings, :dependent => :destroy
  has_many :entries
  has_many :milestones, :dependent => :destroy, :order => :milestone_type_id
  has_many :responsibilities, :dependent => :destroy, :order => :responsibility_type_id

  PROBABILITIES = (0..10).map { |n| n.to_f/10 }.freeze

  accepts_nested_attributes_for :tasks, :reject_if => lambda { |task| task[:name].blank? }
  accepts_nested_attributes_for :project_state
  accepts_nested_attributes_for :milestones
  accepts_nested_attributes_for :responsibilities

  validates_presence_of :shortname, :description, :start, :end,
    :project_state, :wage

  validates_format_of :shortname, :with => /^\w{3}-\d{3}$/

  validates_inclusion_of :probability, :in => Project::PROBABILITIES

  validate :validates_required_responsibilities

  attr_accessible :shortname, :description, :start, :end, :inactive,
    :state, :task_ids, :tasks_attributes, :project_state_id,
    :project_state_attributes, :probability, :wage, :rpl,
    :milestone_ids, :milestones_attributes,
    :responsibility_ids, :responsibilities_attributes,
    :external

  default_scope where(:deleted_at => nil)

  scope :active, where(:inactive => false)

  def set_default_tasks
    APP_CONFIG['default_tasks'].each do |task_name|
      self.tasks.build(:name => task_name)
    end
  end

  def set_default_milestones
    MilestoneType.all.each do |milestone_type|
      self.milestones.build(:milestone_type_id => milestone_type.id)
    end
  end

  def set_default_responsibilities
    ResponsibilityType.all.each do |responsibility_type|
      self.responsibilities.build(:responsibility_type_id => responsibility_type.id)
    end
  end

  # Mark record and related collections as deleted
  def destroy_with_mark
    Project.transaction do
      self.deleted_at = Time.now
      self.save

      self.entries.each do |entry|
        entry.destroy
      end
      self.tasks.each do |task|
        task.destroy
      end
      self.milestones.each do |milestone|
        milestone.destroy
      end
      self.accountings.each do |accounting|
        accounting.destroy
      end
      self.responsibilities.each do |responsibility|
        responsibility.mark_as_deleted
      end
    end
  end

  alias_method_chain :destroy, :mark

  # Cumulated time of all entries
  def duration_hours
    duration = entries.sum :duration
    (duration / 60).to_s + ":" + "%02i" % (duration % 60).to_s
  end

  private

  def validates_required_responsibilities
    self.responsibilities.each do |r|
      if r.user.nil? and r.responsibility_type.required
        errors.add(:base,
                   "Needs a #{r.responsibility_type.name} responsibility")
      end
    end
  end

end
