defmodule GraphvixSpec do
  use ESpec

  describe ".new" do
    it "returns a PID" do
      expect Graphvix.new |> to(be_pid)
    end
  end

  describe ".get" do
    it "returns a hash" do
      expect Graphvix.new |> Graphvix.get |> to(
        eq %{nodes: %{}, edges: %{}, clusters: %{}}
      )
    end
  end

  describe ".add_node" do
    it "returns a node with a unique id" do
      graph = Graphvix.new
      n1 = Graphvix.add_node(graph, label: "Start")
      n2 = Graphvix.add_node(graph, label: "End")
      expect n1.id |> to_not(eq n2.id)
    end
  end

  describe ".add_edge" do
    it "returns an edge with a unique id" do
      graph = Graphvix.new
      n1 = Graphvix.add_node(graph, label: "Start")
      n2 = Graphvix.add_node(graph, label: "End")
      n3 = Graphvix.add_node(graph, label: "Epilogue")

      e1 = Graphvix.add_edge(graph, n1, n2)
      e2 = Graphvix.add_edge(graph, n1, n3)

      expect e1.id |> to_not(eq e2.id)
    end

    it "can create an edge based on node ids" do
      graph = Graphvix.new
      n1 = Graphvix.add_node(graph, label: "Start")
      n2 = Graphvix.add_node(graph, label: "End")
      e1 = Graphvix.add_edge(graph, n1.id, n2.id)

      expect e1 |> Map.get(:attrs) |> to(be_empty)
    end

    it "can create an edge based on nodes" do
      graph = Graphvix.new
      n1 = Graphvix.add_node(graph, label: "Start")
      n2 = Graphvix.add_node(graph, label: "End")
      e1 = Graphvix.add_edge(graph, n1, n2)

      expect e1 |> Map.get(:attrs) |> to(be_empty)
    end
  end

  describe ".add_cluster" do
    it "returns a cluster with a unique id and the provided nodes" do
      graph = Graphvix.new
      n1 = Graphvix.add_node(graph, label: "Start")
      n2 = Graphvix.add_node(graph, label: "End")
      n3 = Graphvix.add_node(graph, label: "Epilogue")

      cluster = Graphvix.add_cluster(graph, [n1, n2, n3])
      expect cluster |> Map.get(:node_ids) |> to(eq [n1.id, n2.id, n3.id])
    end
  end

  describe ".add_to_cluster" do
    it "adds nodes to a cluster" do
      graph = Graphvix.new
      n1 = Graphvix.add_node(graph, label: "Start")
      n2 = Graphvix.add_node(graph, label: "End")
      n3 = Graphvix.add_node(graph, label: "Epilogue")

      cluster = Graphvix.add_cluster(graph, [n1])
      Graphvix.add_to_cluster(graph, cluster.id, n2.id)
      Graphvix.add_to_cluster(graph, cluster.id, [n2, n3])

      expect Graphvix.find(graph, cluster.id) |> Map.get(:node_ids) |> to(eq [n1.id, n2.id, n3.id])
    end
  end

  describe ".remove_from_cluster" do
    it "removes nodes from a cluster" do
      graph = Graphvix.new
      n1 = Graphvix.add_node(graph, label: "Start")
      n2 = Graphvix.add_node(graph, label: "End")
      n3 = Graphvix.add_node(graph, label: "Epilogue")

      cluster = Graphvix.add_cluster(graph, [n1, n2.id, n3])
      Graphvix.remove_from_cluster(graph, cluster.id, n1)

      expect Graphvix.find(graph, cluster.id) |> Map.get(:node_ids) |> to(eq [n2.id, n3.id])
    end
  end

  describe ".find" do
    it "finds an edge or node based on id" do
      graph = Graphvix.new
      n1 = Graphvix.add_node(graph, label: "Start")

      expect Graphvix.find(graph, n1.id) |> to(eq n1)
    end
  end

  describe ".update" do
    it "updates the attributes for an edge or node" do
      graph = Graphvix.new
      n1 = Graphvix.add_node(graph, label: "Start")
      Graphvix.update(graph, n1.id, color: "red")

      expect Graphvix.find(graph, n1.id) |> Map.get(:attrs) |> Keyword.get(:color) |> to(eq "red")
    end

    it "removes the attribute if nil is passed" do
      graph = Graphvix.new
      n1 = Graphvix.add_node(graph, label: "Start", color: "red")
      Graphvix.update(graph, n1.id, color: nil)

      expect Graphvix.find(graph, n1.id) |> Map.get(:attrs) |> to(eq [label: "Start"])
    end
  end

  describe ".remove" do
    it "removes a node, edge, or cluster entirely" do
      graph = Graphvix.new
      n1 = Graphvix.add_node(graph, label: "Start", color: "red")

      Graphvix.remove(graph, n1.id)

      expect Graphvix.get(graph) |> Map.get(:nodes) |> to(be_empty)
    end
  end

  describe ".write" do
    it "returns a dot representation of the graph" do
      expect Graphvix.new |> Graphvix.write |> to(eq "digraph G {\n\n\n}")
    end

    it "returns nodes and edges correctly" do
      graph = Graphvix.new
      n1 = Graphvix.add_node(graph, label: "Start")
      n2 = Graphvix.add_node(graph, label: "End")
      n3 = Graphvix.add_node(graph, label: "Epilogue")
      Graphvix.add_edge(graph, n1, n2)
      Graphvix.add_edge(graph, n1, n3)

      cluster = Graphvix.add_cluster(graph, [n1, n2])

      expect graph |> Graphvix.write |> to(
      eq ~s/
digraph G {
  node_#{n1.id} [label="Start"];
  node_#{n2.id} [label="End"];
  node_#{n3.id} [label="Epilogue"];

  node_#{n1.id} -> node_#{n2.id};
  node_#{n1.id} -> node_#{n3.id};

  subgraph cluster_#{cluster.id} {
    node_#{n1.id} -> node_#{n2.id} [style=invis];
    { rank = "same"; node_#{n1.id}; node_#{n2.id}; }
  }
}/ |> String.strip)
    end
  end

  describe ".save" do
    it "saves at a default file location" do
      g = Graphvix.new

      Graphvix.save(g)

      expect File.rm("G.dot") |> to(eq :ok)
    end

    it "takes an optional filename param" do
      g = Graphvix.new

      Graphvix.save(g, "my_graph")

      expect File.rm("my_graph.dot") |> to(eq :ok)
      expect File.rm("G.dot") |> to(eq {:error, :enoent})
    end
  end

  describe ".compile" do
    it "saves at a default file location and compiles to PDF" do
      g = Graphvix.new

      Graphvix.compile(g)

      expect File.rm("G.dot") |> to(eq :ok)
      expect File.rm("G.pdf") |> to(eq :ok)
    end

    it "saves at a default file location and compiles to PNG if that option is passed in" do
      g = Graphvix.new

      Graphvix.compile(g, "my_graph", :png)

      expect File.rm("my_graph.dot") |> to(eq :ok)
      expect File.rm("my_graph.png") |> to(eq :ok)
      expect File.rm("my_graph.pdf") |> to(eq {:error, :enoent})
    end

    it "allows default filename and format as the second parameter" do
      g = Graphvix.new

      Graphvix.compile(g, :png)

      expect File.rm("G.dot") |> to(eq :ok)
      expect File.rm("G.png") |> to(eq :ok)
      expect File.rm("G.pdf") |> to(eq {:error, :enoent})
    end
  end
end
