System.cmd("epmd", ["-daemon"])
:ok = LocalCluster.start()

ExUnit.start()
