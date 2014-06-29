Fruitbench
==========
A benchmark tool for fruitbots (http://fruitbots.org/).

It measures how your bot is better than others which are written for fruitbots.org. It runs your bot continuously against another bot in order to measure its winning rate.

Instruction
-----------
You should put mybot.js and opbot.js at the top of the directory. each JS files are the same which is uploaded to fruitbots.org. The file tree would be like following.
```
fruitbench/
├─ bench.coffee
├─ mybot.js
├─ opbot.js

```
Then, you can run benchmark as follows.
```
npm install
chmod +x bench.coffee
./bench.coffee -n 100
```
