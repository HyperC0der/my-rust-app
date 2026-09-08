# ================= 第一阶段：编译打包 =================
# 必须使用 >= 1.85 的 Rust 版本以支持 2024 edition，直接使用 alpine 标签即可获取最新稳定版
FROM rust:alpine AS builder

# 安装 musl 构建基础工具集
RUN apk add --no-cache musl-dev

WORKDIR /app

# 1. 复制依赖清单并预编译依赖（利用 Docker 缓存加速以后的代码更新）
COPY Cargo.toml Cargo.lock* ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release
RUN rm -rf src target/release/deps/my_rust_app* target/release/my-rust-app*

# 2. 复制你的真实业务代码并最终打包
COPY src ./src
RUN cargo build --release

# ================= 第二阶段：生产运行镜像 =================
FROM alpine:latest

# 安装基础证书（确保如果你的后端需要通过 HTTPS 访问公网 API 时不会报证书信任错误）
RUN apk add --no-cache ca-certificates

WORKDIR /app

# 从第一阶段拷贝编译出来的可执行文件（注意这里的名字是 my-rust-app，严格对应你的 Cargo.toml name）
COPY --from=builder /app/target/release/my-rust-app /app/server

# 暴露端口声明（Render 实际启动会注入 PORT 环境变量）
EXPOSE 3000

# 运行服务
CMD ["/app/server"]