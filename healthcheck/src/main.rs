use std::{env, process::ExitCode};

fn main() -> ExitCode {
    let port = env::var("ROCKET_PORT").unwrap_or(String::from("8000"));
    let endpoint = format!("http://localhost:{}/heartbeat", port);

    let res = minreq::get(&endpoint).send();

    if res.is_err() {
        println!("{}", res.unwrap_err());
        return ExitCode::from(1);
    }

    let code = res.unwrap().status_code;

    if code < 200 || code > 299 {
        println!("Received status code {}", code);
        return ExitCode::from(1);
    }

    ExitCode::from(0)
}
