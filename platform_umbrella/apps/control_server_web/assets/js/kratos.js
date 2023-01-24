const Kratos = {
  /**
   * Fetches the flow from Kratos and pushes it to the LiveView as an event.
   */
  mounted() {
    const url = this.el.getAttribute('data-url');
    window
      .fetch(url, { credentials: 'include' })
      .then((response) => {
        return response.json();
      })
      .then((data) => {
        this.pushEvent('kratos:loaded', data);
      });
  },
};

export default Kratos;
