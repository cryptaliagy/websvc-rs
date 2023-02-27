use config::{Config, ConfigError, Environment};
use serde::{Deserialize, Serialize};

/// A struct defining default behaviour and deserialization
/// of values for configuring the application.
#[derive(Clone, Debug, Default, Serialize, Deserialize, PartialEq, Eq)]
pub struct AppConfig {
    #[serde(default = "_default_false")]
    profiling: bool,
}

impl AppConfig {
    /// Creates the application config based on environment variables
    pub fn build() -> Result<Self, ConfigError> {
        Config::builder()
            .add_source(Environment::with_prefix("WEBSVC").try_parsing(true))
            .build()?
            .try_deserialize()
    }

    /// Gets a value indicating whether profiling should be
    /// enabled or not.
    pub fn profiling_enabled(&self) -> bool {
        self.profiling
    }

    /// Sets the flag to enable/disable profiling
    pub fn enable_profiling(&mut self, val: bool) {
        self.profiling = val;
    }
}

fn _default_false() -> bool {
    false
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test::serial;
    use std::collections::HashMap;
    use std::env::{self, VarError};

    fn with_env_vars<F>(expected_values: HashMap<&str, &str>, function: F) -> AppConfig
    where
        F: Fn() -> Result<AppConfig, config::ConfigError>,
    {
        let vars: HashMap<&str, Result<String, VarError>> = expected_values
            .iter()
            .map(|(&k, _)| (k, env::var(k)))
            .collect();

        for (k, v) in expected_values {
            env::set_var(k, v);
        }

        // Run closure
        let res = function();

        // Reset value
        for (k, v) in vars {
            if let Ok(val) = v {
                env::set_var(k, val)
            } else {
                env::remove_var(k)
            }
        }

        res.expect("Could not create configuration")
    }

    #[test]
    #[serial]
    fn test_enable_profiling() {
        let values = HashMap::from([("WEBSVC_PROFILING", "1")]);

        let configs = with_env_vars(values, AppConfig::build);

        assert!(configs.profiling_enabled());
        assert!(configs.profiling);
    }
}
