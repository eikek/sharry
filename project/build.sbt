libraryDependencies ++= Seq(
  // elm plugin: minify elm js file
  "com.google.javascript" % "closure-compiler" % "v20170521",

  // webjar plugin
  "org.apache.tika" % "tika-core" % "1.15",
  "io.circe" %% "circe-core" % "0.8.0",
  "io.circe" %% "circe-generic" % "0.8.0"
)
// circe requires this for full generic type class generation in scala 2.10 (which is used by sbt)
addCompilerPlugin(
  "org.scalamacros" % "paradise" % "2.1.0" cross CrossVersion.full
)
