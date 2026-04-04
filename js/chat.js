(function () {
  'use strict';

  // ── Configuration ─────────────────────────────────
  // Replace this URL with your deployed Cloudflare Worker URL
  var API_ENDPOINT = '';
  var MAX_MESSAGES_PER_SESSION = 50;

  // Detect course from the script tag's data attribute
  var scriptTag = document.currentScript;
  var course = scriptTag ? scriptTag.getAttribute('data-course') : 'general';

  // ── State ─────────────────────────────────────────
  var messages = [];
  var messageCount = 0;
  var isOpen = false;
  var isLoading = false;

  // ── Build DOM ─────────────────────────────────────
  function createWidget() {
    // Toggle button
    var toggle = document.createElement('button');
    toggle.className = 'chat-toggle';
    toggle.setAttribute('aria-label', 'Open course assistant');
    toggle.innerHTML =
      '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">' +
      '<path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm0 14H6l-2 2V4h16v12z"/>' +
      '</svg>';
    toggle.addEventListener('click', togglePanel);

    // Panel
    var panel = document.createElement('div');
    panel.className = 'chat-panel';
    panel.id = 'chat-panel';

    var courseName = course === 'us-econ-history'
      ? 'US Economic History'
      : course === 'eu-econ-history'
        ? 'European Economic History'
        : 'Course Assistant';

    panel.innerHTML =
      '<div class="chat-header">' +
      '<span>' + courseName + ' Assistant</span>' +
      '<button class="chat-header-close" aria-label="Close chat">&times;</button>' +
      '</div>' +
      '<div class="chat-messages" id="chat-messages"></div>' +
      '<div class="chat-input-area">' +
      '<input class="chat-input" id="chat-input" type="text" placeholder="Ask about the course..." autocomplete="off">' +
      '<button class="chat-send" id="chat-send">Send</button>' +
      '</div>';

    document.body.appendChild(panel);
    document.body.appendChild(toggle);

    // Event listeners
    panel.querySelector('.chat-header-close').addEventListener('click', togglePanel);
    document.getElementById('chat-send').addEventListener('click', sendMessage);
    document.getElementById('chat-input').addEventListener('keydown', function (e) {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
      }
    });

    // Add welcome message
    addAssistantMessage(
      'Welcome! I can help you explore the course material, explain concepts from the readings, or discuss topics covered in class. What would you like to know?'
    );
  }

  function togglePanel() {
    isOpen = !isOpen;
    var panel = document.getElementById('chat-panel');
    if (isOpen) {
      panel.classList.add('open');
      document.getElementById('chat-input').focus();
    } else {
      panel.classList.remove('open');
    }
  }

  function addUserMessage(text) {
    var container = document.getElementById('chat-messages');
    var msg = document.createElement('div');
    msg.className = 'chat-msg chat-msg-user';
    msg.innerHTML = '<div class="chat-msg-bubble">' + escapeHtml(text) + '</div>';
    container.appendChild(msg);
    container.scrollTop = container.scrollHeight;
  }

  function addAssistantMessage(text) {
    var container = document.getElementById('chat-messages');
    var msg = document.createElement('div');
    msg.className = 'chat-msg chat-msg-assistant';
    msg.innerHTML = '<div class="chat-msg-bubble">' + escapeHtml(text) + '</div>';
    container.appendChild(msg);
    container.scrollTop = container.scrollHeight;
  }

  function showTyping() {
    var container = document.getElementById('chat-messages');
    var typing = document.createElement('div');
    typing.className = 'chat-typing';
    typing.id = 'chat-typing';
    typing.textContent = 'Thinking...';
    container.appendChild(typing);
    container.scrollTop = container.scrollHeight;
  }

  function hideTyping() {
    var typing = document.getElementById('chat-typing');
    if (typing) typing.remove();
  }

  function escapeHtml(text) {
    var div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  function sendMessage() {
    if (isLoading) return;

    var input = document.getElementById('chat-input');
    var text = input.value.trim();
    if (!text) return;

    if (!API_ENDPOINT) {
      addAssistantMessage(
        'The chat assistant is not yet configured. The course instructor needs to deploy the backend service and set the API_ENDPOINT in chat.js.'
      );
      return;
    }

    if (messageCount >= MAX_MESSAGES_PER_SESSION) {
      addAssistantMessage(
        'You have reached the message limit for this session. Please refresh the page to start a new conversation.'
      );
      return;
    }

    // Display and track
    addUserMessage(text);
    input.value = '';
    messageCount++;

    messages.push({ role: 'user', content: text });

    // Call API
    isLoading = true;
    document.getElementById('chat-send').disabled = true;
    showTyping();

    fetch(API_ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        messages: messages,
        course: course
      })
    })
      .then(function (res) {
        if (!res.ok) throw new Error('Request failed');
        return res.json();
      })
      .then(function (data) {
        hideTyping();
        var reply =
          data.content && data.content[0] && data.content[0].text
            ? data.content[0].text
            : 'Sorry, I could not generate a response.';
        messages.push({ role: 'assistant', content: reply });
        addAssistantMessage(reply);
      })
      .catch(function () {
        hideTyping();
        addAssistantMessage('Something went wrong. Please try again.');
      })
      .finally(function () {
        isLoading = false;
        document.getElementById('chat-send').disabled = false;
        document.getElementById('chat-input').focus();
      });
  }

  // ── Initialize ────────────────────────────────────
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', createWidget);
  } else {
    createWidget();
  }
})();
