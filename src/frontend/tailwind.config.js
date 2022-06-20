module.exports = {
	content: ["./index.html", "./src/**/*.{vue,js,ts,jsx,tsx}"],
	theme: {
		fontFamily: {
			inter: "'Inter', sans-serif",
		},
		extend: {
			spacing: {
        '160': '40rem',
      },
			height: {
        '128': '32rem',
      }
		},
	},
	plugins: [],
};
