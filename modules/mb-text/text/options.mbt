///|
pub(all) enum LanguageChoice {
  Default
  Exact(LanguageTag)
} derive(Eq)

///|
pub(all) enum Direction {
  LeftToRight
  RightToLeft
} derive(Eq)

///|
/// Caller-controlled optional feature policy. Required LangSys features and
/// supported `rlig` behavior are intentionally not disableable.
pub struct FeaturePolicy {
  priv liga_value : Bool
  priv kern_value : Bool
}

///|
pub fn FeaturePolicy::new(liga~ : Bool, kern~ : Bool) -> FeaturePolicy {
  { liga_value: liga, kern_value: kern }
}

///|
pub fn FeaturePolicy::liga(self : FeaturePolicy) -> Bool {
  self.liga_value
}

///|
pub fn FeaturePolicy::kern(self : FeaturePolicy) -> Bool {
  self.kern_value
}

///|
pub struct ShapingOptions {
  priv script_value : ScriptTag
  priv language_value : LanguageChoice
  priv direction_value : Direction
  priv features_value : FeaturePolicy
}

///|
pub fn ShapingOptions::new(
  script : ScriptTag,
  language : LanguageChoice,
  direction : Direction,
  features : FeaturePolicy,
) -> ShapingOptions {
  {
    script_value: script,
    language_value: language,
    direction_value: direction,
    features_value: features,
  }
}

///|
pub fn ShapingOptions::script(self : ShapingOptions) -> ScriptTag {
  self.script_value
}

///|
pub fn ShapingOptions::language(self : ShapingOptions) -> LanguageChoice {
  self.language_value
}

///|
pub fn ShapingOptions::direction(self : ShapingOptions) -> Direction {
  self.direction_value
}

///|
pub fn ShapingOptions::features(self : ShapingOptions) -> FeaturePolicy {
  self.features_value
}

///|
fn ShapingOptions::validate(
  self : ShapingOptions,
) -> Result[Unit, @error.CoreError] {
  match self.script_value.validate() {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match self.language_value {
    LanguageChoice::Default => Ok(())
    LanguageChoice::Exact(language) => language.validate()
  }
}
