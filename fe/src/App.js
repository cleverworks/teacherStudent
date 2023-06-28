import React, { Component } from "react";
import { Routes, Route, Link } from "react-router-dom";
import "bootstrap/dist/css/bootstrap.min.css";
import "./App.css";

// Grade related thigns
import AddGrade from "./components/grades/add-grade.component";
import Grade from "./components/grades/grade.component";
import GradesList from "./components/grades/grades-list.component";

// Subject related things
import AddSubject from "./components/subjects/add-subject.component";
import Subject from "./components/subjects/subject.component";
import SubjectsList from "./components/subjects/subjects-list.component";

class App extends Component {
  render() {
    return (
      <div>
        <nav className="navbar navbar-expand navbar-dark bg-dark">
          <Link to={"/grades"} className="navbar-brand">
            Teching App
          </Link>
          <div className="navbar-nav mr-auto">
            <li className="nav-item">
              <Link to={"/grades"} className="nav-link">
                Grades
              </Link>
            </li>
            <li className="nav-item">
              <Link to={"/subjects"} className="nav-link">
                Subjects
              </Link>
            </li>
          </div>
        </nav>

        <div className="container mt-3">
          <Routes>
            <Route path="/" element={<GradesList/>} />
            <Route path="/grades" element={<GradesList/>} />
            <Route path="/add_grade" element={<AddGrade/>} />
            <Route path="/grades/:id" element={<Grade/>} />
            
            <Route path="/subjects" element={<SubjectsList/>} />
            <Route path="/add_subject" element={<AddSubject/>} />
            <Route path="/subjects/:id" element={<Subject/>} />
          </Routes>
        </div>
      </div>
    );
  }
}

export default App;
