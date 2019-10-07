# frozen_string_literal: true

class DotVisitor < Visitor
  Node = Struct.new(:id, :node) do
    STATE_COLORS = {
      complete: "darkgreen",
      failed: "firebrick1",
      in_progress: "goldenrod1",
      retrying: "goldenrod1"
    }.freeze

    def name
      node.class.name
    end

    def to_dot
      <<~EODOT
        #{id} [label="<f0> #{name}", fontcolor=#{color}, color=#{color}];
      EODOT
    end

    def color
      return "black" unless node.respond_to?(:state)

      STATE_COLORS.fetch(node.state, "black")
    end
  end

  Edge = Struct.new(:origin, :destination) do
    def color
      destination.color
    end

    def to_dot
      <<~EODOT
        #{origin.id} -> #{destination.id} [color=#{color}];
      EODOT
    end
  end

  HEADER = <<~EODOT
    digraph "Graph" {
    node [width=0.375,height=0.25,shape = "record"];
  EODOT

  FOOTER = "}"

  attr_reader :edges, :nodes, :stack

  def initialize
    @edges = []
    @stack = []
    @nodes = {}
  end

  # rubocop:disable Metrics/AbcSize
  def visit(job)
    return connect(nodes[job_id(stack.last)], nodes[job_id(job)]) if nodes.key?(job_id(job))

    nodes[job_id(job)] = node = Node.new(nodes.size + 1, job)
    connect(nodes[job_id(stack.last)], node) unless stack.empty?
    stack.push(job)
    super
    stack.pop
  end
  # rubocop:enable Metrics/AbcSize

  def to_dot
    dot = HEADER.dup
    nodes.values.each { |node| dot.concat(node.to_dot) }
    edges.each { |edge| dot.concat(edge.to_dot) }
    dot + FOOTER
  end

  private

  def job_id(job)
    job.persisted? ? job.id : job.object_id
  end

  def connect(origin, destination)
    edges.push(Edge.new(origin, destination))
  end
end
