class FakeRecord
  attr_reader :previous_changes, :created_at, :updated_at

  def initialize
    @updated_at = Time.zone.today.beginning_of_day - 1.day
  end

  def create
    @created_at = Time.zone.today.beginning_of_day
    @updated_at = Time.zone.today.beginning_of_day

    self
  end

  def update
    @updated_at = Time.zone.today.end_of_day

    self
  end

  def delete
    @previous_changes = {}

    self
  end

  def previous_changes
    @previous_changes ||= { 'message' => ['hello', 'world'] }
  end

  def updated_at
    @updated_at
  end

  def created_at
    @created_at
  end
end
