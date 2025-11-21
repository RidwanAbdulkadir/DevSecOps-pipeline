document.addEventListener('DOMContentLoaded', () => {
  console.log('App loaded!');
  
  // Example: Focus on the input field when page loads
  const input = document.querySelector('.add-form input');
  if (input) {
    input.focus();
  }
});

