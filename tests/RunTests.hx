package ;

class RunTests {

  static function main() {
    travix.Logger.println('it works');
    travix.Logger.exit(0); // make sure we exit properly, which is necessary on some targets, e.g. flash & (phantom)js
  }
  
}

class MyConfig extends why.Config {
  
  var env:why.config.Source = why.config.EnvVar.inst;
  var ssm:why.config.Source = new why.config.AwsSsm();
  
  
  @:source(env)
  @:key('JJ')
  public var TEST1:String;
  
  @:source(ssm)
  @:key('JJ')
  public var TEST2:String;
}