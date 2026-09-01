package main

import (
	"sync"
	"time"
)

var (
	Epoch     int64 = 1288834974657
	NodeBits  uint8 = 10
	StepBits  uint8 = 12
	nodeMax   int64 = -1 ^ (-1 << NodeBits)
	nodeMask        = nodeMax << StepBits
	stepMask  int64 = -1 ^ (-1 << StepBits)
	timeShift       = NodeBits + StepBits
	nodeShift       = StepBits
)

type Node struct {
	mu        sync.Mutex
	epoch     time.Time
	time      int64
	node      int64
	step      int64
	nodeMax   int64
	stepMask  int64
	timeShift uint8
	nodeShift uint8
}
