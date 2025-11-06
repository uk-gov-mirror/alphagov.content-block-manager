/* global Turbo */

describe('GOVUK.Modules.HostContentIframe', function () {
  'use strict'

  let module
  let instance

  beforeEach(function () {
    window.Turbo = {
      visit: jasmine.createSpy('visit')
    }

    module = createIframe()
    instance = new window.GOVUK.Modules.HostContentIframe(module)
    instance.init()

    triggerLoadEvent(module)
  })

  afterEach(function () {
    document.body.removeChild(module)
    delete window.Turbo
  })

  describe('when clicking a link', function () {
    let link

    beforeEach(function () {
      link = module.contentDocument.querySelector('a')
    })

    it('sets cursor to wait', function () {
      link.click()
      expect(link.style.cursor).toBe('wait')
    })

    it('calls navigateViaTurbo with the link href', function () {
      link.click()
      expect(Turbo.visit).toHaveBeenCalledWith('https://example.gov.uk/test', {
        frame: 'preview_frame_123',
        action: 'advance'
      })
    })
  })

  describe('when submitting a form', function () {
    let submitButton
    let mockResponse
    let form
    let submitEvent

    beforeEach(function () {
      form = module.contentDocument.querySelector('form')
      submitButton = form.querySelector('button')

      mockResponse = {
        url: 'https://example.gov.uk/success'
      }

      spyOn(window, 'fetch').and.returnValue(Promise.resolve(mockResponse))

      submitEvent = new window.CustomEvent('submit', {})
      submitEvent.submitter = submitButton
    })

    it('sets cursor to wait on the submitter', function () {
      form.dispatchEvent(submitEvent)

      expect(submitButton.style.cursor).toBe('wait')
    })

    it('submits form data via fetch', function () {
      form.dispatchEvent(submitEvent)

      expect(fetch).toHaveBeenCalledWith(
        'https://example.gov.uk/submit',
        jasmine.objectContaining({
          method: 'POST',
          body: jasmine.any(FormData),
          headers: {
            Accept: 'text/vnd.turbo-stream.html, text/html',
            'X-Requested-With': 'XMLHttpRequest'
          }
        })
      )
    })

    it('navigates to the response URL on success', function (done) {
      form.dispatchEvent(submitEvent)

      setTimeout(function () {
        expect(Turbo.visit).toHaveBeenCalledWith(
          'https://example.gov.uk/success',
          { frame: 'preview_frame_123', action: 'advance' }
        )
        done()
      }, 50)
    })

    it('logs error on fetch failure', function (done) {
      const error = new Error('Network error')
      fetch.and.returnValue(Promise.reject(error))
      spyOn(console, 'error')

      form.dispatchEvent(submitEvent)

      setTimeout(function () {
        expect(console.error).toHaveBeenCalledWith(
          'Form submission error:',
          error
        )
        done()
      }, 50)
    })
  })

  const createIframe = () => {
    const iframe = document.createElement('iframe')
    iframe.setAttribute('data-edition-id', '123')
    iframe.id = 'test-iframe'

    const iframeDoc = createHtmlDoc()

    Object.defineProperty(iframe, 'contentDocument', {
      writable: true,
      value: iframeDoc
    })

    document.body.appendChild(iframe)

    return iframe
  }

  const createHtmlDoc = () => {
    const doc = document.implementation.createHTMLDocument('Test Document')

    const link = doc.createElement('a')
    link.href = 'https://example.gov.uk/test'
    doc.body.appendChild(link)

    const form = document.createElement('form')
    form.action = 'https://example.gov.uk/submit'

    const input = document.createElement('input')
    input.name = 'field1'
    input.value = 'value1'
    form.appendChild(input)

    const submitButton = document.createElement('button')
    submitButton.type = 'submit'
    form.appendChild(submitButton)

    doc.body.appendChild(form)

    return doc
  }

  const triggerLoadEvent = (module) => {
    const loadEvent = new Event('load')
    Object.defineProperty(loadEvent, 'target', {
      writable: true,
      value: module
    })
    module.dispatchEvent(loadEvent)
  }
})
