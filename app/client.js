#!/usr/bin/env node

/**
 * Client library for Playwright Renderer Service
 * Usage: const renderer = require('./client');
 */

const http = require('http');
const https = require('https');
const fs = require('fs');

class RendererClient {
  constructor(baseUrl = 'http://localhost:3000') {
    this.baseUrl = baseUrl;
  }

  /**
   * Convert HTML string to image
   * @param {string} html - HTML content
   * @param {object} options - Render options
   * @returns {Promise<{imageBase64, contentType, size, format}>}
   */
  async renderHTML(html, options = {}) {
    return this._request('POST', '/render', { html, options });
  }

  /**
   * Render URL to image
   * @param {string} url - URL to render
   * @param {object} options - Render options
   * @returns {Promise<{imageBase64, contentType, size, format, url}>}
   */
  async renderURL(url, options = {}) {
    return this._request('POST', '/render-url', { url, options });
  }

  /**
   * Queue async render job
   * @param {string} html - HTML content
   * @param {object} options - Render options
   * @returns {Promise<{jobId, statusUrl}>}
   */
  async renderAsync(html, options = {}) {
    return this._request('POST', '/render-async', { html, options });
  }

  /**
   * Get async job status
   * @param {string} jobId - Job ID
   * @returns {Promise<object>}
   */
  async getJobStatus(jobId) {
    return this._request('GET', `/render-async/${jobId}`);
  }

  /**
   * Download rendered image to file
   * @param {string} jobId - Job ID
   * @param {string} outputPath - File path to save
   * @returns {Promise<void>}
   */
  async downloadImage(jobId, outputPath) {
    return new Promise((resolve, reject) => {
      const protocol = this.baseUrl.startsWith('https') ? https : http;
      const url = new URL(`/download/${jobId}`, this.baseUrl);

      protocol
        .get(url, (res) => {
          if (res.statusCode !== 200) {
            reject(new Error(`Failed to download: ${res.statusCode}`));
            return;
          }

          const fileStream = fs.createWriteStream(outputPath);
          res.pipe(fileStream);

          fileStream.on('finish', () => {
            fileStream.close();
            resolve();
          });

          fileStream.on('error', reject);
        })
        .on('error', reject);
    });
  }

  /**
   * Check service health
   * @returns {Promise<{status}>}
   */
  async health() {
    return this._request('GET', '/health');
  }

  /**
   * Get service status
   * @returns {Promise<object>}
   */
  async status() {
    return this._request('GET', '/status');
  }

  _request(method, path, body = null) {
    return new Promise((resolve, reject) => {
      const protocol = this.baseUrl.startsWith('https') ? https : http;
      const url = new URL(path, this.baseUrl);

      const options = {
        hostname: url.hostname,
        port: url.port,
        path: url.pathname + url.search,
        method,
        headers: {
          'Content-Type': 'application/json',
        },
      };

      const req = protocol.request(options, (res) => {
        let data = '';

        res.on('data', (chunk) => {
          data += chunk;
        });

        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            if (res.statusCode >= 400) {
              reject(new Error(parsed.error || `HTTP ${res.statusCode}`));
            } else {
              resolve(parsed);
            }
          } catch (e) {
            reject(new Error(`Invalid JSON response: ${data}`));
          }
        });
      });

      req.on('error', reject);

      if (body) {
        req.write(JSON.stringify(body));
      }

      req.end();
    });
  }
}

module.exports = RendererClient;
