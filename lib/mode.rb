class Mode
  attr_reader :name, :val, :p1, :p2, :p3

  def initialize(params)
    @name = params[:name]
    @val = params[:val]
    @p1 = params[:p1]
    @p2 = params[:p2]
    @p3 = params[:p3]
  end
end