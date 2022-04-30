package main

import (
	"fmt"
	"io/ioutil"
	"log"
)

func main() {
	prom, e := ioutil.ReadFile("tbp24s10_7a.ic52")
	if e != nil {
		log.Fatal(e)
	}
	hsync := 1
	hb := 1
	for h := 0; h < 0x200; h++ {
		last_hs := hsync
		last_hb := hb
		addr := h & 0xf
		addr |= (h >> 1) & 0x1f0
		if h&0xf == 0xf {
			hsync = int( (prom[addr] >> 3) & 1 )
		}
		if (h&0x80==0x80) && (h&0x100==0x100) {
			hb = int( (prom[addr] >> 1) & 1 )
		}
		if hsync != last_hs {
			fmt.Printf("%03X HS = %d\n", h, hsync)
		}
		if hb != last_hb {
			fmt.Printf("%03X HB = %d\n", h, hb)
		}
	}
}
