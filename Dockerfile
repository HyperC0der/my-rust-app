# ================= 第一阶段：编译打包 =================
FROM rust:1.79-alpine AS builder

# 安装 musl 构建依赖
RUN apk add --no-cache musl-dev

WORKDIR /app

# 1. 先只复制依赖清单，利用 Docker 缓存加速以后的重新构建
COPY Cargo.toml Cargo.lock* ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release
RUN rm -f src/main.rs target/release/deps/my_axum_app*

# 2. 复制真实源码并编译
COPY src ./src
RUN cargo build --release

# ================= 第二阶段：极限精简运行时 =================
FROM alpine:latest

# 安装必要的基础证书（如果你的代码未来需要发起 HTTPS 请求）
RUN apk add --no-cache ca-certificates

WORKDIR /app

# 从构建阶段只拷贝编译好的二进制可执行文件（名字对应你的 Cargo.toml 里的 name）
COPY --from=builder /app/target/release/my-axum-app /app/server

# 容器启动命令
CMD ["/app/server"]