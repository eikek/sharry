libraryDependencies ++= Seq(
  // elm plugin: minify elm js file
  "com.google.javascript" % "closure-compiler" % "v20170910",

  // webjar plugin
  "org.apache.tika" % "tika-core" % "1.17",
  "io.circe" %% "circe-core" % "0.9.2",
  "io.circe" %% "circe-generic" % "0.9.2"
)
