libraryDependencies ++= Seq(
  // elm plugin: minify elm js file
  "com.google.javascript" % "closure-compiler" % "v20170910",

  // webjar plugin
  "org.apache.tika" % "tika-core" % "1.16",
  "io.circe" %% "circe-core" % "0.8.0",
  "io.circe" %% "circe-generic" % "0.8.0"
)
