onTabChanged: (index) {
                    const paths = ['/home', '/transactions', '/budgets', '/goals', '/profile'];
                    context.go(paths[index]);
                  },