libraryDependencies ++= Seq(
  // elm plugin: minify elm js file
  "com.google.javascript" % "closure-compiler" % "v20161201",

  // webjar plugin
  "org.apache.tika" % "tika-core" % "1.14",
  "io.circe" %% "circe-core" % "0.6.1",
  "io.circe" %% "circe-generic" % "0.6.1"
)
// circe requires this for full generic type class generation in scala 2.10 (which is used by sbt)
addCompilerPlugin(
  "org.scalamacros" % "paradise" % "2.1.0" cross CrossVersion.full
)
