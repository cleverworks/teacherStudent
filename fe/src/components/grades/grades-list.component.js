import React, { Component } from "react";
import GradeDataService from "../../services/grade.service";
import { Link } from "react-router-dom";

export default class GradesList extends Component {
  constructor(props) {
    super(props);
    this.onChangeSearchTitle = this.onChangeSearchTitle.bind(this);
    this.retrieveGrades = this.retrieveGrades.bind(this);
    this.refreshList = this.refreshList.bind(this);
    this.setActiveGrade = this.setActiveGrade.bind(this);
    this.removeAllGrades = this.removeAllGrades.bind(this);
    this.searchTitle = this.searchTitle.bind(this);

    this.state = {
      grades: [],
      currentGrade: null,
      currentIndex: -1,
      searchTitle: ""
    };
  }

  componentDidMount() {
    this.retrieveGrades();
  }

  onChangeSearchTitle(e) {
    const searchTitle = e.target.value;

    this.setState({
      searchTitle: searchTitle
    });
  }

  retrieveGrades() {
    GradeDataService.getAll()
      .then(response => {
        this.setState({
          grades: response.data
        });
        console.log(response.data);
      })
      .catch(e => {
        console.log(e);
      });
  }

  refreshList() {
    this.retrieveGrades();
    this.setState({
      currentGrade: null,
      currentIndex: -1
    });
  }

  setActiveGrade(grade, index) {
    this.setState({
      currentGrade: grade,
      currentIndex: index
    });
  }

  removeAllGrades() {
    GradeDataService.deleteAll()
      .then(response => {
        console.log(response.data);
        this.refreshList();
      })
      .catch(e => {
        console.log(e);
      });
  }

  searchTitle() {
    this.setState({
      currentGrade: null,
      currentIndex: -1
    });

    GradeDataService.findByTitle(this.state.searchTitle)
      .then(response => {
        this.setState({
          grades: response.data
        });
        console.log(response.data);
      })
      .catch(e => {
        console.log(e);
      });
  }

  render() {
    const { searchTitle, grades, currentGrade, currentIndex } = this.state;

    return (
      <div className="list row">
        <div className="col-md-8">
          <div className="input-group mb-3">
            <input
              type="text"
              className="form-control"
              placeholder="Search by title"
              value={searchTitle}
              onChange={this.onChangeSearchTitle}
            />
            <div className="input-group-append">
              <button
                className="btn btn-outline-secondary"
                type="button"
                onClick={this.searchTitle}
              >
                Search
              </button>
            </div>
          </div>
        </div>
        <div className="col-md-6">
          <h4>Grades List</h4>

          <ul className="list-group">
            {grades &&
              grades.map((grade, index) => (
                <li
                  className={
                    "list-group-item " +
                    (index === currentIndex ? "active" : "")
                  }
                  onClick={() => this.setActiveGrade(grade, index)}
                  key={index}
                >
                  {grade.title}
                </li>
              ))}
          </ul>

          <button
            className="m-3 btn btn-sm btn-danger"
            onClick={this.removeAllGrades}
          >
            Remove All
          </button>
          <Link to={"/add_grade"} className="m-3 btn btn-sm btn-success">
            Add New
          </Link>
        </div>
        <div className="col-md-6">
          {currentGrade ? (
            <div>
              <h4>Grade</h4>
              <div>
                <label>
                  <strong>Title:</strong>
                </label>{" "}
                {currentGrade.title}
              </div>
              <div>
                <label>
                  <strong>Description:</strong>
                </label>{" "}
                {currentGrade.descr}
              </div>
              <div>
                <label>
                  <strong>Status:</strong>
                </label>{" "}
                {currentGrade.published ? "Published" : "Pending"}
              </div>

              <Link
                to={"/grades/" + currentGrade._id.$oid}
                className="badge badge-warning"
              >
                Edit
              </Link>
            </div>
          ) : (
            <div>
              <br />
              <p>Please click on a Grade...</p>
            </div>
          )}
        </div>
      </div>
    );
  }
}
