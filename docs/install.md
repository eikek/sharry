[Contents](index.md)

# Installation

## Get Sharry

There are two ways to get Sharry: download the source and build it
yourself or download a prebuild executable.

### Download

There are prebuild files for download:

- [Sharry {{version}}](https://eknet.org/main/projects/sharry/sharry-server-{{version}}.jar.sh)

This is a bash script that can be run in any Linux distribution and
OSX that has JRE 8 installed. On Ubuntu, for example, this can be done
using this command:

```
sudo apt-get install openjdk-8-jre
```

Windows users: I'm sorry there is no binary for windows. If you can
help out, I'd appreciate pull requests. But not everything is lost,
you should be able to run this file with a longer command:

```
java -jar /path/to/sharry-server-{{version}}.jar.sh
```


### Build

Building the application is not so hard, actually. You'll need the following tools:

- [Elm](http://elm-lang.org)
- [Sbt](http://scala-sbt.org)
- [JDK 8](http://openjdk.java.net/projects/jdk8/)
- [Git](http://git-scm.com)

Here are commands that install these things on Ubuntu (disclaimer: I
just tried it on Ubuntu 16.04 server edition, but I never used Ubuntu
myself, so take these tips with some salt):

```
sudo apt-get install git openjdk-8-jdk npm nodejs-legacy
```

Install Elm via npm and node:

```
sudo npm install -g elm elm-test
```

Install sbt, see [sbt homepage](http://www.scala-sbt.org/download.html) for instructiions.  One possible
way is probably the debian variant, because I couldn't find it via
`apt-cache search`:

```
echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
sudo apt-get update
sudo apt-get install sbt
```

Now you can clone and build sharry:

```
git clone https://github.com/eikek/sharry.git
cd sharry
sbt make
```

This will take a while. The final product can be found here:

```
modules/server/target/scala-2.12/sharry-server-$version.jar.sh
```
