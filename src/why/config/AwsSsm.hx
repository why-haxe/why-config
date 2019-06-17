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
		}, $cb1).next(function(data):Array<String> {
			var params = data.Parameters;
			params.sort(function(v1, v2) return Reflect.compare(names.indexOf(v1.Name), names.indexOf(v2.Name)));
			return [for(p in params) p.Value];
		});
	}
}