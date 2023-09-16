# requires
# pip install aiomcache
import aiomcache
import asyncio
import json
import pprint
# orjson faster alternative: pip install orjson


async def main():
    memcached = aiomcache.Client('localhost', 11211)

    value = await memcached.get(b"quik#status")

    d = json.loads(value.decode('cp1251'))
    pprint.pprint(d)

if __name__ == "__main__":
    asyncio.run(main())
