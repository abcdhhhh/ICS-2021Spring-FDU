#include "mycache.h"
#include "cache_ref.h"

CacheRefModel::CacheRefModel(MyCache *_top, size_t memory_size)
    : top(_top), scope(top->VCacheTop), mem(memory_size) {
    /**
     * TODO (Lab3) setup reference model :)
     */

    mem.set_name("ref");
}

void CacheRefModel::reset() {
    /**
     * TODO (Lab3) reset reference model :)
     */

    log_debug("ref: reset()\n");
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 4; j++)
            for (int k = 0; k < 4; k++) cache_data[i][j][k]=0;
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 4; j++){
            meta[i].tag[j]=0;
            meta[i].valid[j]=meta[i].dirty[j]=false;
        }
    mem.reset();
}

auto CacheRefModel::load(addr_t addr, AXISize size) -> word_t {
    /**
     * TODO (Lab3) implement load operation for reference model :)
     */

    log_debug("ref: load(0x%x, %d)\n", addr, 1 << size);

    addr_t start = addr / 16 * 16;
    int tag = addr / 64;
    int index = addr / 16 % 4;
    int offset = addr / 4 % 4;
    int position = 0;
    bool hit=false;
    // get position
    for (int i = 0; i < 4; i++) {
        if(meta[index].valid[i] && meta[index].tag[i]==tag){
            position=i;
            hit=true;
            break;
        }
    }
    // check: reorder
    for(int i=position; i<3; i++) {
        for(int j=0; j<4; j++){
            std::swap(cache_data[index][i][j], cache_data[index][i+1][j]);
        }    
        std::swap(meta[index].tag[i], meta[index].tag[i+1]);   
        std::swap(meta[index].valid[i], meta[index].valid[i+1]);   
        std::swap(meta[index].dirty[i], meta[index].dirty[i+1]);     
    }

    if(hit) return cache_data[index][3][offset];

    // flush
    if(meta[index].dirty[3]) {
        for(int j=0; j<4; j++){
            mem.store(meta[index].tag[3]*64+index*16+j*4, cache_data[index][3][j], STROBE_TO_MASK[0xf]);
        }
    }
    
    //fetch
    for(int j=0; j<4; j++) {
        cache_data[index][3][j] = mem.load(start + 4 * j);
    }
    meta[index].tag[3] = tag;
    meta[index].valid[3] = true;
    meta[index].dirty[3] = false;
    
    return cache_data[index][3][offset];
}

void CacheRefModel::store(addr_t addr, AXISize size, word_t strobe, word_t data) {
    /**
     * TODO (Lab3) implement store operation for reference model :)
     */

    log_debug("ref: store(0x%x, %d, %x, \"%08x\")\n", addr, 1 << size, strobe, data);

    addr_t start = addr / 16 * 16;
    int tag = addr / 64;
    int index = addr / 16 % 4;
    int offset = addr / 4 % 4;
    int position = 0;
    bool hit=false;
    // get position
    for (int i = 0; i < 4; i++) {
        if(meta[index].valid[i] && meta[index].tag[i]==tag){
            position=i;
            hit=true;
            break;
        }
    }
    // check: reorder
    for(int i=position; i<3; i++) {
        for(int j=0; j<4; j++){
            std::swap(cache_data[index][i][j], cache_data[index][i+1][j]);
        }  
        std::swap(meta[index].tag[i], meta[index].tag[i+1]);   
        std::swap(meta[index].valid[i], meta[index].valid[i+1]);   
        std::swap(meta[index].dirty[i], meta[index].dirty[i+1]);     
    }

    auto mask = STROBE_TO_MASK[strobe];
    auto &value = cache_data[index][3][offset];

    // flush
    if(hit){
        value = (data & mask) | (value & ~mask);
        meta[index].dirty[3] = true;
        return;
    }

    if(meta[index].dirty[3]) {
        for(int j=0; j<4; j++){
            mem.store(meta[index].tag[3]*64+index*16+j*4, cache_data[index][3][j], STROBE_TO_MASK[0xf]);
        }
    }

    //fetch
    for(int j=0; j<4; j++) {
        cache_data[index][3][j] = mem.load(start + 4 * j);
    }
    meta[index].tag[3] = tag;
    meta[index].valid[3] = true;
    meta[index].dirty[3] = false;
    
    value = (data & mask) | (value & ~mask);
    meta[index].dirty[3] = true;
}

void CacheRefModel::check_internal() {
    /**
     * TODO (Lab3) compare reference model's internal states to RTL model :)
     *
     * NOTE: you can use pointer top and scope to access internal signals
     *       in your RTL model, e.g., top->clk, scope->mem.
     */

    log_debug("ref: check_internal()\n");

    /**
     * the following comes from StupidBuffer's reference model.
     */
    // for (int i = 0; i < 16; i++) {
    //     asserts(
    //         buffer[i] == scope->mem[i],
    //         "reference model's internal state is different from RTL model."
    //         " at mem[%x], expected = %08x, got = %08x",
    //         i, buffer[i], scope->mem[i]
    //     );
    // }
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 4; j++)
            for (int k = 0; k < 4; k++) {
                asserts(
                    cache_data[i][j][k] == scope->mem[i*16+j*4+k],
                    "reference model's internal state is different from RTL model."
                    " at mem[%x][%x][%x], expected = %08x, got = %08x",
                    i, j, k, cache_data[i][j][k], scope->mem[i*16+j*4+k]
                );
            }
}

void CacheRefModel::check_memory() {
    /**
     * TODO (Lab3) compare reference model's memory to RTL model :)
     *
     * NOTE: you can use pointer top and scope to access internal signals
     *       in your RTL model, e.g., top->clk, scope->mem.
     *       you can use mem.dump() and MyCache::dump() to get the full contents
     *       of both memories.
     */

    log_debug("ref: check_memory()\n");

    /**
     * the following comes from StupidBuffer's reference model.
     */
    asserts(mem.dump(0, mem.size()) == top->dump(), "reference model's memory content is different from RTL model");
}
