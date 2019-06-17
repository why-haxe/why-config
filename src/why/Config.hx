package why;

#if !macro
using tink.CoreApi;

@:autoBuild(why.Config.build())
class Config {
	public function new() {}
	public function prepare():Promise<Noise> throw 'abstract';
}

#else

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;

using tink.CoreApi;
using tink.MacroApi;

class Config {
	
	static var SOURCE:Lazy<Type> = Context.getType.bind('why.config.Source');
	static var STRING:Lazy<Type> = Context.getType.bind('String');
	
	public static function build() {
		var builder = new ClassBuilder();
		
		var sources = getSources(builder);
		var entries = getEntries(builder, sources);
		var grouped = [for(source in sources) source => []];
		
		if(sources.length == 0) Context.currentPos().error('Missing source');
		
		for(entry in entries) {
			switch [sources, entry.source] {
				case [[single], source]: grouped[single].push(entry); // TODO: warn if @:source is specified, because it will be ignored
				case [_, None]: entry.field.pos.error('@:source metadata is required when multiple sources are defined.');
				case [_, Some(source)]: grouped[source].push(entry);
			}
		}
		
		var preparations = [for(source in sources) {
			var access = macro $i{source}
			var entries = grouped[source];
			var keys = [for(entry in entries) {
				var key = entry.key;
				macro $v{key}
			}];
			
			var pattern = [for(i in 0...entries.length) {
				capture: macro $i{'_$i'},
				entry: entries[i],
			}];
			
			var cases = [{
				values: {
					var names = [for(p in pattern) p.capture];
					[macro $a{names}];
				},
				expr: {
					var assignments = macro $b{[for(p in pattern) macro $i{p.entry.field.name} = ${p.capture}]}
					assignments.concat(macro tink.core.Noise.Noise.Noise);
				},
				guard: null,
			}];
			var arg = macro $a{keys}
			macro $access.get($arg).next(function(values) return ${ESwitch(macro values, cases, macro new tink.core.Error('Invalid return values')).at()});
		}];
		
		var preparations = macro $a{preparations}
		builder.addMembers(macro class {
			override function prepare() {
				return tink.core.Promise.inParallel($preparations).noise();
			}
		}); // [0].getFunction().sure().expr.log();
		
		return builder.export();
	}
	
	static function getSources(builder:ClassBuilder):Sources {
		return [for(member in builder) {
			switch member.kind {
				case FVar(ct, _) if(ct.toType().sure().unifiesWith(SOURCE)): member.name;
				case _: continue;
			}
		}];
	}
	
	static function getEntries(builder:ClassBuilder, sources:Sources):Array<Entry> {
		return [for(member in builder) {
			switch member.kind {
				case FVar(ct, null) if(ct.toType().sure().unifiesWith(STRING)): {
					field: member,
					key: switch member.metaNamed(':key') {
						case []:
							member.name;
						case [{params: [_.getName() => Success(key)]}]:
							key;
						case _:
							member.pos.error('Only support single @:key metadata and it should have exactly one parameter');
					},
					source: switch member.metaNamed(':source') {
						case []:
							None;
						case [{params: [e = _.getName() => Success(source)]}] if(sources.exists(source)):
							Some(source);
						case [{params: [e = _.getName() => Success(source)]}]:
							e.pos.error('Unknown source "$source"');
						case _:
							member.pos.error('Only support single @:source metadata and it should have exactly one parameter');
					},
				}
				case _: continue;
			}
		}];
	}
}

@:forward
private abstract Sources(Array<String>) from Array<String> to Array<String> {
	public inline function exists(v:String) return this.indexOf(v) != -1;
}

private typedef Entry = {
	key:String,
	source:Option<String>,
	field:Field,
}
#end