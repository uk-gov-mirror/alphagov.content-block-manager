/* global Turbo */
'use strict'
window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {}
;(function (Modules) {
  function HostContentIframe(module) {
    this.module = module
    this.frameId = 'preview_frame_' + module.dataset.editionId
  }

  HostContentIframe.prototype.init = function () {
    this.module.addEventListener('load', this.setup.bind(this))
  }

  HostContentIframe.prototype.setup = function (e) {
    const iframeDoc = e.target.contentDocument

    const links = iframeDoc.querySelectorAll('a')
    const forms = iframeDoc.querySelectorAll('form')

    links.forEach((link) => {
      link.addEventListener('click', this.captureLinkClick.bind(this))
    })

    forms.forEach((form) => {
      form.addEventListener('submit', this.captureFormSubmit.bind(this))
    })
  }

  HostContentIframe.prototype.captureLinkClick = function (event) {
    event.preventDefault()
    event.target.style.cursor = 'wait'
    this.navigateViaTurbo(event.target.href)
  }

  HostContentIframe.prototype.captureFormSubmit = function (event) {
    event.preventDefault()
    event.submitter.style.cursor = 'wait'
    const form = event.target
    const formData = new FormData(form)
    const method = 'POST'
    const action = form.action

    fetch(action, {
      method,
      body: formData,
      headers: {
        Accept: 'text/vnd.turbo-stream.html, text/html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
      .then((response) => {
        this.navigateViaTurbo(response.url)
      })
      .catch((error) => console.error('Form submission error:', error))
  }

  HostContentIframe.prototype.navigateViaTurbo = function (href) {
    Turbo.visit(href, { frame: this.frameId, action: 'advance' })
  }

  Modules.HostContentIframe = HostContentIframe
})(window.GOVUK.Modules)
