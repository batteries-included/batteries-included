const KratosFlow = {
  /**
   * Fetches the flow from Kratos and pushes it to the LiveView as an event.
   */
  mounted() {
    const flow_id = this.el.getAttribute('data-flow-id');
    const url = this.el.getAttribute('data-flow-url');
    window
      .fetch(url + new URLSearchParams({ id: flow_id }), {
        credentials: 'include',
      })
      .then((response) => {
        return response.json();
      })
      .then((data) => {
        console.log(data);
        this.pushEvent('kratos_flow:loaded', data);
      });
  },
};

export default KratosFlow;
