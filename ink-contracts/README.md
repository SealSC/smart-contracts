# Installing



Please make sure that you have these prerequisites installed on your computer:

Install [rustup](https://rustup.rs/) to manager rust's toolchain

then run: 

```rustup component add rust-src --toolchain nightly```

```rustup target add wasm32-unknown-unknown --toolchain stable```

Then you have to install ink! command line utility which will make setting up Substrate smart contract projects easier:

```cargo install cargo-contract --force```



# Lint

```cargo clippy```



# Testing

```cargo test```



# Build Contract

Enter every contract directory then run

```
cargo contract build
```



The target wasm will at target/ink/<contract_name>/<contract_name>.wasm