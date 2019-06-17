package why.config;

using tink.CoreApi;

@:build(futurize.Futurize.build())
class AwsSsm implements Source {
	var ssm:js.aws.ssm.SSM;
	
	public function new(?opt) {
		ssm = new js.aws.ssm.SSM(opt);
	}
	
	public function get(names:Array<String>):Promise<Array<String>> {
		return @:futurize ssm.getParameters({
			Names: names,
			WithDecryption: true,
		}, $cb1).next(function(data):Array<String> return [for(p in data.Parameters) p.Value]);
	}
}