// fn main() {
//     println!("Hello, world!");
// }

use axum::{routing::get, Router};
use std::net::SocketAddr;
use std::env;

#[tokio::main]
async fn main() {
    // 构建路由
    let app = Router::new()
        .route("/", get(|| async { "Hello from Axum on Render!" }))
        .route("/health", get(|| async { "OK" }));

    // 关键点：动态读取 Render 注入的 PORT 环境变量，默认兜底 3000
    let port: u16 = env::var("PORT")
        .unwrap_or_else(|_| "3000".to_string())
        .parse()
        .expect("PORT 必须是有效数字");

    // 关键点：绑定 0.0.0.0
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    println!("Axum 正在监听：{}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}