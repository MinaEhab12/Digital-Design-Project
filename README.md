# Digital Design Project

##  Overview

This project implements a **Cross-Clock Domain Data Processing Unit** in RTL. The system safely transfers data between different clock domains using an **Asynchronous FIFO**, then performs high-speed computation using a **32-bit Parallel Prefix Adder**.

The design addresses one of the key challenges in modern SoC systems: **clock domain crossing (CDC)** and high-performance arithmetic processing.

---

## Project Structure

```
Digital-Design-Project/
│
├── designs/
│   ├── Async FIFO/
│   ├── adder/
│
└── testbench/
```

---

## Key Components

### 1. Asynchronous FIFO (CDC Handling)

The FIFO enables safe data transfer between:

* Write Clock Domain: **20 MHz**
* Read Clock Domain: **100 MHz**

#### Features:

* Dual-port memory (independent read/write clocks)
* Gray-coded read/write pointers
* Two-flop synchronizers for CDC safety
* Full and Empty flag generation

#### Purpose:

Prevents **metastability** and ensures reliable communication between asynchronous clock domains.

---

### 2. 32-bit Parallel Prefix Adder (High-Speed Computation)

A custom high-performance adder implemented without using the `+` operator.

#### Architecture Options:

* Kogge-Stone Adder
* Brent-Kung Adder

#### Implementation Stages:

1. **Pre-processing**

   * Generate (G) = A AND B
   * Propagate (P) = A XOR B

2. **Prefix Tree (Dot Operator)**

   * G = G₁ OR (P₁ AND G₂)
   * P = P₁ AND P₂

3. **Post-processing**

   * Sum[i] = P[i] XOR Carry[i-1]

#### Purpose:

Achieves faster computation compared to ripple-carry adders with delay of **O(log₂N)**.

---

##  System Flow

1. Input data arrives at **20 MHz**
2. Data is written into the **Async FIFO**
3. Data is safely transferred to the **100 MHz domain**
4. Data is read from FIFO when not empty
5. Passed to the **Parallel Prefix Adder**
6. Result is generated at high speed

---

##  Assumptions

* FIFO depth: 16 or 32 entries
* Data width: 32 bits
* No use of built-in `+` operator for the adder
* Synchronization handled using 2-flip-flop synchronizers

---

##  Verification

Testbenches are included to verify:

* FIFO full and empty conditions
* Correct clock domain crossing behavior
* Adder correctness for different input cases
* Extend design to support wider data paths
* Optimize area vs speed trade-offs
* Implement on FPGA for hardware validation

---
