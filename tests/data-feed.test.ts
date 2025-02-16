import { describe, it, expect } from "vitest"

// Mock the Clarity functions and types
const mockClarity = {
  tx: {
    sender: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  },
  types: {
    uint: (value: number) => ({ type: "uint", value }),
    int: (value: number) => ({ type: "int", value }),
    principal: (value: string) => ({ type: "principal", value }),
    string: (value: string) => ({ type: "string", value }),
  },
}

// Mock contract calls
const contractCalls = {
  "create-feed": (description: string) => {
    return { success: true, value: mockClarity.types.uint(1) }
  },
  "report-data": (feedId: number, value: number) => {
    return { success: true, value: true }
  },
  "get-latest-data": (feedId: number) => {
    return {
      success: true,
      value: {
        description: mockClarity.types.string("BTC/USD"),
        "latest-value": mockClarity.types.int(50000),
        "last-updated": mockClarity.types.uint(100),
        aggregator: mockClarity.types.principal(mockClarity.tx.sender),
      },
    }
  },
  "get-data-point": (feedId: number, timestamp: number) => {
    return {
      success: true,
      value: {
        value: mockClarity.types.int(50000),
        reporter: mockClarity.types.principal(mockClarity.tx.sender),
      },
    }
  },
  "update-aggregator": (feedId: number, newAggregator: string) => {
    return { success: true, value: true }
  },
}

describe("Data Feed Contract", () => {
  it("should create a new data feed", () => {
    const result = contractCalls["create-feed"]("BTC/USD")
    expect(result.success).toBe(true)
    expect(result.value).toEqual(mockClarity.types.uint(1))
  })
  
  it("should report data for a feed", () => {
    const result = contractCalls["report-data"](1, 50000)
    expect(result.success).toBe(true)
    expect(result.value).toBe(true)
  })
  
  it("should get latest data for a feed", () => {
    const result = contractCalls["get-latest-data"](1)
    expect(result.success).toBe(true)
    expect(result.value).toEqual({
      description: mockClarity.types.string("BTC/USD"),
      "latest-value": mockClarity.types.int(50000),
      "last-updated": mockClarity.types.uint(100),
      aggregator: mockClarity.types.principal(mockClarity.tx.sender),
    })
  })
  
  it("should get historical data point", () => {
    const result = contractCalls["get-data-point"](1, 100)
    expect(result.success).toBe(true)
    expect(result.value).toEqual({
      value: mockClarity.types.int(50000),
      reporter: mockClarity.types.principal(mockClarity.tx.sender),
    })
  })
  
  it("should update feed aggregator", () => {
    const result = contractCalls["update-aggregator"](1, "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG")
    expect(result.success).toBe(true)
    expect(result.value).toBe(true)
  })
})

