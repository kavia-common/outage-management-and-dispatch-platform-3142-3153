'use strict';

const path = require('path');
const fs = require('fs');

describe('db_visualizer smoke tests', () => {
  test('server.js exists (project is wired correctly)', () => {
    const serverPath = path.join(__dirname, '..', 'server.js');
    expect(fs.existsSync(serverPath)).toBe(true);
  });

  test('public/index.html exists (static UI is present)', () => {
    const indexPath = path.join(__dirname, '..', 'public', 'index.html');
    expect(fs.existsSync(indexPath)).toBe(true);
  });
});
