const app = document.querySelector<HTMLElement>('#app');

if (app) {
  const heading = document.createElement('h1');
  heading.textContent = '${{ values.name }}';

  const summary = document.createElement('p');
  summary.textContent = '${{ values.description }}';

  app.replaceChildren(heading, summary);
}
