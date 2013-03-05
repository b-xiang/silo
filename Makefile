CXXFLAGS := -Wall -Werror -g -O2
#CXXFLAGS := -Wall -g

LDFLAGS := -lpthread

# 0 = libc malloc
# 1 = jemalloc
# 2 = tcmalloc
USE_MALLOC_MODE=1

ifeq ($(USE_MALLOC_MODE),1)
        CXXFLAGS+=-DUSE_JEMALLOC
        LDFLAGS+=-ljemalloc 
        #LDFLAGS+=-L$(HOME)/jemalloc-bin/lib -ljemalloc 
else
ifeq ($(USE_MALLOC_MODE),2)
        CXXFLAGS+=-DUSE_TCMALLOC
        LDFLAGS+=-ltcmalloc
endif
endif

HEADERS = btree.h macros.h rcu.h static_assert.h thread.h txn.h txn_btree.h varkey.h util.h \
	  spinbarrier.h counter.h core.h imstring.h lockguard.h spinlock.h hash_bytes.h \
	  xbuf.h small_vector.h small_unordered_map.h
SRCFILES = btree.cc counter.cc core.cc rcu.cc thread.cc txn.cc \
	txn_btree.cc varint.cc memory.cc hash_bytes.cc
OBJFILES = $(SRCFILES:.cc=.o)

MYSQL_SHARE_DIR=/x/stephentu/mysql-5.5.29/build/sql/share

BENCH_CXXFLAGS := $(CXXFLAGS) -DMYSQL_SHARE_DIR=\"$(MYSQL_SHARE_DIR)\"
BENCH_LDFLAGS := $(LDFLAGS) -ldb_cxx -lmysqld -lz -lrt -lcrypt -laio -ldl -lssl -lcrypto

BENCH_HEADERS = $(HEADERS) \
	benchmarks/abstract_db.h \
	benchmarks/abstract_ordered_index.h \
	benchmarks/bench.h \
	benchmarks/inline_str.h \
	benchmarks/encoder.h \
	benchmarks/serializer.h \
	benchmarks/bdb_wrapper.h \
	benchmarks/ndb_wrapper.h \
	benchmarks/mysql_wrapper.h \
	benchmarks/tpcc.h
BENCH_SRCFILES = \
	benchmarks/bdb_wrapper.cc \
	benchmarks/ndb_wrapper.cc \
	benchmarks/mysql_wrapper.cc \
	benchmarks/tpcc.cc \
	benchmarks/ycsb.cc \
	benchmarks/queue.cc \
	benchmarks/encstress.cc
BENCH_OBJFILES = $(BENCH_SRCFILES:.cc=.o)

all: test

benchmarks/%.o: benchmarks/%.cc $(BENCH_HEADERS)
	$(CXX) $(BENCH_CXXFLAGS) -c $< -o $@

%.o: %.cc $(HEADERS)
	$(CXX) $(CXXFLAGS) -c $< -o $@

test: test.cc $(OBJFILES)
	$(CXX) $(CXXFLAGS) -o test $^ $(LDFLAGS)

.PHONY: bench
bench: benchmarks/bench

benchmarks/bench: benchmarks/bench.cc $(OBJFILES) $(BENCH_OBJFILES)
	$(CXX) $(BENCH_CXXFLAGS) -o benchmarks/bench $^ $(BENCH_LDFLAGS)

.PHONY: clean
clean:
	rm -f *.o test benchmarks/*.o benchmarks/bench
